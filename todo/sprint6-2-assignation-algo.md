# DEV 3389 — SPRINT 6 : ALGORITHME D'ASSIGNATION DES VÉHICULES

## Objectif

Adapter la logique d'assignation dans `PlanningDao` et `PlanningController` pour ajouter :

- La **disponibilité par heure de retour** (un véhicule occupé n'est plus disponible)
- Le **choix par nombre de trajets** puis priorité carburant
- La **persistance en base** (table `assignation`)
- La **gestion des réservations en attente** (réévaluées au prochain groupe horaire)
- Le **tag "DÉCALÉE"** en UI pour les réservations traitées après leur heure d'arrivée

> **Prérequis** : le travail du DEV 3383 (modèles, DAO, scripts SQL) doit être mergé avant de commencer.

---

## Ce qui NE CHANGE PAS (règles des sprints précédents conservées)

> **Toutes les règles métier existantes restent en place. On en ajoute, on n'en remplace pas.**

- Un véhicule peut toujours transporter **plusieurs réservations** (places partagées)
- Le regroupement par `tempsAttente` (30 min) fonctionne comme avant
- Les réservations d'un groupe sont triées par `nbPassager DESC`
- On cherche d'abord un véhicule déjà utilisé dans le vol, puis un nouveau
- Le calcul de distance greedy (aéroport le plus proche, nearest neighbor) reste identique
- Le calcul de l'heure de retour (distance / vitesse moyenne) reste identique

---

## 1. Adapter `PlanningDao.planifier()`

Fichier : `src/main/java/dao/PlanningDao.java`

### Pseudo-code de la méthode adaptée

Le traitement se fait **d'un seul coup pour toute la journée**. Quand on lance la planification d'une date, on parcourt TOUS les groupes horaires et on retourne un résultat complet.

``` txt
planifier(date, vols, vehicules):

    // ÉTAPE 1 : Supprimer les anciennes assignations de la date
    assignationDao.supprimerParDate(date)

    // ÉTAPE 2 : Initialiser les compteurs
    vehiculeHeureRetour = {}    // idVehicule -> heure de retour du dernier trajet
    trajetsParVehicule = {}     // idVehicule -> nombre de trajets effectués
    reservationsEnAttente = []  // réservations non assignées à reporter au groupe suivant

    // ÉTAPE 3 : Parcourir TOUS les groupes horaires de la journée (triés par heure)
    pour chaque groupe (heureDepart, listeReservations) dans vols (trié par heureDepart ASC) :

        // Ajouter les réservations en attente des groupes précédents
        listeReservations = listeReservations + reservationsEnAttente
        reservationsEnAttente = []

        // Trier par nbPassager DESC (règle existante conservée)
        trier listeReservations par nbPassager DESC

        // ================================================================
        // BOUCLE INTERNE AU GROUPE
        // ================================================================
        // On ne fait pas qu'un seul passage. Si des véhicules reviennent
        // PENDANT la fenêtre du groupe (ex: retour à 08:25 dans le groupe
        // 08:00-08:30), ils redeviennent disponibles et on retente
        // d'assigner les réservations restantes.
        //
        // L'heure de départ effective du groupe s'ajuste au fur et à mesure
        // (= la plus tardive entre l'heure de départ initiale et l'heure
        //    de retour du véhicule qui vient de se libérer).
        // ================================================================

        heureFinGroupe = heureDepart + tempsAttente   // ex: 08:00 + 30min = 08:30
        heureDepartEffective = heureDepart
        nonAssigneesGroupe = listeReservations         // à traiter

        repeter :
            placesRestantes = initialiserPlacesRestantes(vehicules, vehiculeHeureRetour, heureDepartEffective)
            assignationsPassage = {}
            encoreNonAssignees = []

            pour chaque reservation dans nonAssigneesGroupe :

                vehiculeChoisi = chercherVehiculeDejaUtilise(...)  // règle existante
                si vehiculeChoisi == null :
                    vehiculeChoisi = chercherNouveauVehicule(...)  // règle existante

                si vehiculeChoisi == null :
                    encoreNonAssignees.add(reservation)
                    continuer

                // Assigner (logique existante conservée : places partagées)
                assignerReservation(...)

                // Persister en base
                assignation = new Assignation(vehiculeChoisi.id, reservation.id, reservation.decalee)
                assignationDao.insert(assignation)

            // Calculer les trajets de ce passage
            creerTrajetsPourVol(heureDepartEffective, assignationsPassage, vehicules, vitesseMoyenne, vehiculeHeureRetour, trajets)

            // Incrémenter le compteur de trajets par véhicule
            pour chaque vehiculeId dans assignationsPassage.keys() :
                trajetsParVehicule[vehiculeId] += 1

            // Vérifier si des véhicules reviennent DANS la fenêtre du groupe
            // et s'il reste des réservations à traiter
            si encoreNonAssignees est vide :
                sortir de la boucle   // tout est assigné, on passe au groupe suivant

            // Chercher le prochain véhicule qui se libère dans la fenêtre
            plusProchaineDisponibilite = null
            pour chaque (vehiculeId, heureRetour) dans vehiculeHeureRetour :
                si heureRetour > heureDepartEffective ET heureRetour <= heureFinGroupe :
                    si plusProchaineDisponibilite == null OU heureRetour < plusProchaineDisponibilite :
                        plusProchaineDisponibilite = heureRetour

            si plusProchaineDisponibilite == null :
                sortir de la boucle   // aucun véhicule ne revient dans la fenêtre

            // Un véhicule revient dans la fenêtre → on retente avec l'heure ajustée
            heureDepartEffective = plusProchaineDisponibilite
            nonAssigneesGroupe = encoreNonAssignees

        fin repeter

        // Les réservations encore non assignées après la boucle interne
        // → reportées au prochain groupe (décalées)
        pour chaque reservation dans encoreNonAssignees :
            reservation.decalee = true
            reservationsEnAttente.add(reservation)

    // ÉTAPE 4 : Les réservations encore en attente après le DERNIER groupe
    // → aucun véhicule disponible sur toute la journée
    // → on les retourne dans la liste "nonAssignees" pour affichage
    pour chaque reservation dans reservationsEnAttente :
        nonAssignees.add(reservation)
```

### Résumé de la boucle interne

Exemple concret avec le groupe **08:00-08:30** :

``` txt
1er passage (heureDepartEffective = 08:00) :
  → VAN-1 disponible → assigne R1 et R3
  → Aucun autre véhicule → R4 non assignée
  → Calcul trajet VAN-1 : retour à 08:25

2e passage (heureDepartEffective = 08:25, car VAN-1 revient dans la fenêtre) :
  → VAN-1 redevient disponible à 08:25 → assigne R4
  → Heure de départ de ce sous-trajet = 08:25
  → Plus rien à traiter → sortie de boucle

Résultat du groupe :
  - VAN-1 fait 2 trajets : départ 08:00 puis départ 08:25
  - Toutes les réservations sont assignées
  - Aucune reportée au groupe suivant
```

### Tâches concrètes dans `PlanningDao.java`

- [ ] Ajouter les champs `AssignationDao assignationDao` et `ReservationDao reservationDao`
- [ ] Ajouter le paramètre `String date` à la signature de `planifier()`
- [ ] Ajouter la suppression des anciennes assignations au début
- [ ] Ajouter la liste `reservationsEnAttente` pour reporter les non-assignées au groupe suivant
- [ ] **Conserver** `initialiserPlacesRestantes()` mais y intégrer le check `heureRetour <= heureDepart`
- [ ] **Conserver** `assignerReservationsVol()`, `chercherVehiculeDejaUtilise()`, `chercherNouveauVehicule()`
- [ ] Ajouter la persistance (insert assignation) après chaque assignation réussie
- [ ] Implémenter la **boucle interne au groupe** : après chaque passage, vérifier si un véhicule revient dans la fenêtre et retenter les non-assignées
- [ ] Ajuster `heureDepartEffective` à chaque passage interne (= heure de retour du véhicule qui se libère)
- [ ] Marquer `reservation.decalee = true` uniquement quand une réservation est reportée à un **autre groupe**
- [ ] Retourner dans `nonAssignees` uniquement les réservations qui n'ont trouvé aucun véhicule après le DERNIER groupe

---

## 2. Adapter `choisirMeilleurVehicule()` (nouvelles règles de priorité)

Fichier : `src/main/java/dao/PlanningDao.java`

On **garde** la méthode existante mais on **ajoute** les nouveaux critères de tri :

1. **Places restantes >= nbPassagers** (existant, conservé)
2. **Plus petit véhicule qui convient** (existant, conservé)
3. **NOUVEAU : moins de trajets effectués** (départage)
4. **Priorité carburant** : D > ES > H (existant élargi — avant c'était juste Diesel prioritaire)

```java
/**
 * Parmi les candidats, choisit le meilleur véhicule.
 * Critères (dans l'ordre) :
 *   1. Moins de places restantes (plus petit qui convient) — EXISTANT
 *   2. Moins de trajets effectués dans la journée — NOUVEAU
 *   3. Priorité carburant : D > ES > H — ÉLARGI
 */
private Integer choisirMeilleurVehicule(
        List<Vehicule> candidats,
        Map<Integer, Integer> placesRestantes,
        Map<Integer, Integer> trajetsParVehicule) {
    // ...
}

private int prioriteCarburant(String typeCarburant) {
    if ("D".equals(typeCarburant)) return 3;
    if ("ES".equals(typeCarburant)) return 2;
    if ("H".equals(typeCarburant)) return 1;
    return 0;
}
```

- [ ] Ajouter le paramètre `trajetsParVehicule` à `choisirMeilleurVehicule()`
- [ ] Ajouter le tri par nombre de trajets (après le tri par places restantes)
- [ ] Implémenter `prioriteCarburant()` et l'utiliser dans le départage
- [ ] Mettre à jour les appels à `choisirMeilleurVehicule()` dans `chercherVehiculeDejaUtilise()` et `chercherNouveauVehicule()`

---

## 3. Adapter `initialiserPlacesRestantes()` (ajouter check heure de retour)

Fichier : `src/main/java/dao/PlanningDao.java`

La méthode existe déjà et vérifie `heureRetour <= heureDepart`. **Elle est déjà correcte pour le Sprint 6** — juste vérifier qu'elle fonctionne bien avec le nouveau flux.

```java
// EXISTANT — déjà bon, juste vérifier
private Map<Integer, Integer> initialiserPlacesRestantes(
    List<Vehicule> vehicules,
    Map<Integer, String> vehiculeHeureRetour,
    String heureVol) {
    // ... véhicule disponible si heureRetour == null ou heureRetour <= heureVol
}
```

- [ ] Vérifier que `initialiserPlacesRestantes()` fonctionne correctement avec le nouveau flux
- [ ] Aucune suppression de méthode — on garde tout

---

## 4. Mettre à jour `PlanningController.java`

Fichier : `src/main/java/controller/PlanningController.java`

### Nouveau flux dans `handleDateForm()`

```java
@Post("/planning")
public ModelView handleDateForm(@requestParam("date") String date) {
    // ...

    // 1. Réservations du jour
    List<Reservation> reservationsJour = reservationDao.findByDate(date);

    // 2. Véhicules et paramètres (inchangé)
    List<Vehicule> vehicules = vehiculeDao.findAll();
    int tempsAttente = parametreDao.getTempsAttente();

    // 3. Regrouper par vol avec temps d'attente (inchangé)
    Map<String, List<Reservation>> vols = reservationDao.regrouperParVol(reservationsJour, tempsAttente);

    // 4. Planifier — NOUVEAU : passer la date
    //    L'algorithme traite toute la journée d'un coup et retourne le résultat complet
    Map<String, Object> resultat = planningDao.planifier(date, vols, vehicules);

    // 5. Résultat : trajets + nonAssignees (inchangé)
    // ...
}
```

- [ ] Passer `date` à `planifier()`
- [ ] Vérifier que la vue affiche correctement le résultat complet de la journée

---

## 5. Mettre à jour la vue `planningResult.jsp`

Fichier : `src/main/webapp/WEB-INF/views/planningResult.jsp`

La vue doit afficher **tout d'un coup** : toutes les assignations de la journée.

### 5.1 Résultat global de la journée

- [ ] Afficher **tous les trajets** de la journée (tous les groupes horaires)
- [ ] Afficher le **nombre de trajets** effectués par chaque véhicule

### 5.2 Tag "DÉCALÉE" pour les réservations traitées en retard

Une réservation est **décalée** si elle n'a pas trouvé de véhicule dans son groupe d'origine et a été **reportée à un groupe horaire ultérieur**.

**Exemple :** R4 (arrivée 08:08) tombe dans le groupe 08:00-08:30. Aucun véhicule disponible → reportée. Prochain groupe : 10:00-10:30 → R4 est traitée ici → `decalee = true`.

**Comment le détecter :** le flag `decalee` est posé en backend quand la réservation est mise en attente, puis stocké dans l'assignation lors de l'insertion.

**Affichage en UI :**

- [ ] Ajouter un tag/badge visuel (ex: `<span class="badge badge-warning">DÉCALÉE</span>`) sur chaque réservation décalée
- [ ] Afficher l'heure d'arrivée d'origine ET l'heure de départ effective

**Exemple d'affichage :**

``` txt
GROUPE 08:30 — VAN-1 (8 places)
  #1001 | 3 passagers | Colbert | Arrivée 08:00
  #1003 | 4 passagers | Ibis    | Arrivée 08:15

GROUPE 09:25 — MINIBUS-1 (15 places)
  #1004 | 7 passagers | Lokanga | Arrivée 08:08  [DÉCALÉE]
  #1005 | 8 passagers | Carlton | Arrivée 09:00

NON ASSIGNÉES (aucun véhicule disponible sur toute la journée)
  #1011 | 5 passagers | Ibis    | Arrivée 10:00
```

### 5.3 Section "Non assignées"

- [ ] Afficher les réservations qui n'ont trouvé **aucun véhicule sur toute la journée**
- [ ] Ces réservations n'ont simplement pas de ligne dans la table `assignation`

---

## Résumé des fichiers à modifier (DEV 3389)

| Fichier                                            | Action                                                                       |
|----------------------------------------------------|------------------------------------------------------------------------------|
| `src/main/java/dao/PlanningDao.java`               | **Adapter** — ajouter persistance, report au groupe suivant, critère trajets |
| `src/main/java/controller/PlanningController.java` | **Modifier** — passer date à planifier()                                     |
| `src/main/webapp/WEB-INF/views/planningResult.jsp` | **Modifier** — tag DÉCALÉE, résultat complet journée                         |

---

## Critères de validation

### Règles conservées (vérifier qu'elles marchent toujours)

- [ ] Un véhicule peut transporter **plusieurs réservations** (places partagées)
- [ ] Le regroupement par `tempsAttente` (30 min) fonctionne
- [ ] Les réservations sont triées par `nbPassager DESC` dans chaque groupe
- [ ] On cherche d'abord un véhicule déjà utilisé dans le vol, puis un nouveau
- [ ] Le calcul de distance greedy fonctionne
- [ ] Le calcul de l'heure de retour fonctionne

### Nouvelles règles Sprint 6

- [ ] Lancer la génération **supprime les anciennes assignations** de la date
- [ ] Le **traitement couvre toute la journée** d'un coup (tous les groupes horaires)
- [ ] Un véhicule n'est pas disponible tant que `heureRetour > heureDepart` du groupe
- [ ] Le véhicule est choisi avec le **moins de trajets**, puis **priorité carburant D > ES > H**
- [ ] **Boucle interne** : si un véhicule revient dans la fenêtre du groupe, il est réutilisé pour les réservations restantes
- [ ] L'heure de départ effective s'ajuste à chaque passage interne
- [ ] Une réservation n'est reportée au groupe suivant que si **aucun véhicule ne se libère dans la fenêtre**
- [ ] Les réservations non assignées après le **dernier groupe** sont retournées dans la liste `nonAssignees`
- [ ] Les réservations traitées en décalage affichent un **tag "DÉCALÉE"** en UI
- [ ] Les assignations sont **persistées en base** (table `assignation`)
- [ ] Les non-assignées se déduisent de l'absence de ligne dans `assignation` (pas de champ `status` en base)

---

## Dépendances

> **Tu as besoin du travail du DEV 3383** avant de commencer :
>
> - Le modèle `Assignation.java` (avec champ `decalee`)
> - Le DAO `AssignationDao.java` (méthodes `supprimerParDate`, `insert`, `compterTrajetsParVehicule`)
> - Le script SQL de migration

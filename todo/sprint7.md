# DEV 3390 — SPRINT 7 : FRACTIONNEMENT DES RÉSERVATIONS

## Objectif

Permettre de **fractionner une réservation sur plusieurs véhicules** quand elle ne rentre pas en entier dans un seul véhicule.

Actuellement : si une réservation de 23 passagers et que le plus grand véhicule a 10 places, la réservation n'est pas assignée.

**Après Sprint 7** : la réservation est divisée et assignée à plusieurs véhicules :
- VAN-1 : 10 passagers
- VAN-2 : 8 passagers
- VAN-3 : 5 passagers

Si des passagers restent non assignés à la fin de la journée, ils sont reportés (avec `decalee=true`).

> **Prérequis** : le travail du Sprint 6 (modèle `Assignation`, DAO, boucle interne) doit être en place.

---

---

## 📝 EXPLICATION RAPIDE (à utiliser comme prompt)

**Le problème actuellement** : si une réservation de N passagers ne rentre pas dans UN seul véhicule, elle n'est pas assignée du tout.

**La solution Sprint 7** : diviser la réservation sur **plusieurs véhicules**.

### Algorithme simple

```
Pour chaque réservation R (triée par nbPassager DESC) :

  1. Chercher UN véhicule qui peut la prendre en entier
     → Si trouvé : assignation complète, passer à la suivante

  2. Sinon, fractionner sur les véhicules dispo (du plus grand au plus petit)
     → Chaque fraction = une ligne assignation DISTINCTE en base
     → Incrémenter le nbPassagerAffecte de chaque fraction

  3. S'il reste des passagers non assignés :
     → Créer une pseudo-réservation "reliquat" avec decalee=true
     → Reporter au groupe horaire suivant
     → Si c'est le dernier groupe : dans nonAssignees
```

### Exemple concret (cas PO)

```
État : V1 (8 places), V2 (3 places)

Traiter R1 (6 passagers) :
  → V1 peut le prendre en entier
  → V1 : R1 complète (6), reste 2 places libres

Traiter R2 (4 passagers) :
  → V1 (2 libres) ne suffit pas, V2 (3 libres) ne suffit pas
  → Fractionner :
      - V1 prend 2 de R2 → insert assignation(V1, R2, nbPassagerAffecte=2)
      - V2 prend 2 de R2 → insert assignation(V2, R2, nbPassagerAffecte=2)
  → R2 complète assignée

Traiter R3 (3 passagers) :
  → V1 (0 libres), V2 (1 libre) → aucun ne suffit
  → Fractionner :
      - V2 prend 1 de R3 → insert assignation(V2, R3, nbPassagerAffecte=1)
  → R3 : 2 passagers restent non assignés
  → Créer reliquat R3_restant(2) avec decalee=true
  → Si pas de groupe suivant : dans nonAssignees
```

---

## Règles de gestion (NEW)

1. **Trier par nbPassager DESC** — on assigne les plus grosses réservations en premier (existant, conservé)
2. **Essayer assignation complète d'abord** — chercher un seul véhicule pour toute la réservation
3. **Si aucun ne suffit** — fractionner sur plusieurs véhicules disponibles (NEW)
4. **Prioriser les plus grands véhicules libres** — places restantes DESC (NEW)
5. **Une ligne assignation par fraction** — chaque fraction créé une ligne en base (NEW)
6. **Reliquat reporte** — si du reliquat après le dernier groupe → `decalee=true` (NEW)

```
Véhicules disponibles :
  - V1 : 8 places libres
  - V2 : 3 places libres

Réservations à traiter (par nbPassager DESC) :
  - R1 : 6 passagers
  - R2 : 4 passagers
  - R3 : 3 passagers

Traitement :
1. R1 (6) : cherche un seul véhicule → V1 (8) convient → R1 complète dans V1
   Résultat : V1 a 2 places restantes

2. R2 (4) : cherche un seul véhicule → V1 (2) ne suffit pas, V2 (3) ne suffit pas
   → Fractionner sur V1 et V2 :
      - V1 prend 2 (places restantes)
      - V2 prend 2 (places restantes)
   Résultat : V1 plein, V2 plein, reliquat R2 = 0
   Ajout en base :
     - assignation(V1, R2, nbPassagerAffecte=2, decalee=false)
     - assignation(V2, R2, nbPassagerAffecte=2, decalee=false)

3. R3 (3) : cherche un seul véhicule → aucun ne convient
   → Fractionner : aucun véhicule disponible
   → Reliquat R3 = 3 (reporté au groupe suivant ou nonAssignees)
   Si fin de journée : R3 dans "nonAssignees" avec decalee=true
```

---

## 1. Créer le script de migration

Fichier : `script/20260318/db_20260318_sprint7.sql`

**Action** : ajouter la colonne `nbPassagerAffecte` à la table `assignation` dans les 3 schémas (dev, staging, prod).

Cette colonne stocke **le nombre réel de passagers assignés à cette fraction** (différent de `reservation.nbPassager` si la réservation est fractionnée).

```sql
-- ============================================================
-- SPRINT 7 : Colonne nbPassagerAffecte pour fractionnement
-- ============================================================

-- ============================================================
-- DEV
-- ============================================================
ALTER TABLE dev.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE dev.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM dev.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE dev.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE dev.assignation ADD CONSTRAINT assignation_nbpassageraffe_check CHECK (nbPassagerAffecte > 0);

-- ============================================================
-- STAGING
-- ============================================================
ALTER TABLE staging.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE staging.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM staging.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE staging.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE staging.assignation ADD CONSTRAINT assignation_nbpassageraffe_check_staging CHECK (nbPassagerAffecte > 0);

-- ============================================================
-- PROD
-- ============================================================
ALTER TABLE prod.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE prod.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM prod.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE prod.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE prod.assignation ADD CONSTRAINT assignation_nbpassageraffe_check_prod CHECK (nbPassagerAffecte > 0);
```

- [ ] Créer le fichier SQL
- [ ] Exécuter sur dev, staging, prod

---

## 2. Mettre à jour le modèle `Assignation`

Fichier : `src/main/java/model/Assignation.java`

**Modification** : ajouter le champ `nbPassagerAffecte` et mettre à jour les constructeurs, getters/setters.

```java
package model;

public class Assignation {
    private int id;
    private int idVehicule;
    private int idReservation;
    private int nbPassagerAffecte;      // NEW — nombre réel assigné (peut être < reservation.nbPassager)
    private boolean decalee;
    private String datePlanification;

    // Constructeur vide
    public Assignation() {}

    // Constructeur complet
    public Assignation(int idVehicule, int idReservation, int nbPassagerAffecte, boolean decalee) {
        this.idVehicule = idVehicule;
        this.idReservation = idReservation;
        this.nbPassagerAffecte = nbPassagerAffecte;
        this.decalee = decalee;
    }

    // Getters et setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getIdVehicule() { return idVehicule; }
    public void setIdVehicule(int idVehicule) { this.idVehicule = idVehicule; }

    public int getIdReservation() { return idReservation; }
    public void setIdReservation(int idReservation) { this.idReservation = idReservation; }

    public int getNbPassagerAffecte() { return nbPassagerAffecte; }
    public void setNbPassagerAffecte(int nbPassagerAffecte) { this.nbPassagerAffecte = nbPassagerAffecte; }

    public boolean isDecalee() { return decalee; }
    public void setDecalee(boolean decalee) { this.decalee = decalee; }

    public String getDatePlanification() { return datePlanification; }
    public void setDatePlanification(String datePlanification) { this.datePlanification = datePlanification; }

    @Override
    public String toString() {
        return "Assignation{" +
                "id=" + id +
                ", idVehicule=" + idVehicule +
                ", idReservation=" + idReservation +
                ", nbPassagerAffecte=" + nbPassagerAffecte +
                ", decalee=" + decalee +
                ", datePlanification='" + datePlanification + '\'' +
                '}';
    }
}
```

- [ ] Ajouter le champ `nbPassagerAffecte`
- [ ] Mettre à jour les 2 constructeurs
- [ ] Ajouter getter/setter pour `nbPassagerAffecte`
- [ ] Mettre à jour `toString()`

---

## 3. Mettre à jour le DAO `AssignationDao`

Fichier : `src/main/java/dao/AssignationDao.java`

**Modifications** :
1. Adapter les requêtes SQL pour inclure `nbPassagerAffecte`
2. Ajouter le mapping `rs.getInt("nbPassagerAffecte")` dans tous les `ResultSet`

### 3.1 Méthode `insert()`

```java
/**
 * Insère une nouvelle assignation en base.
 * La réservation peut être fractionnée : nbPassagerAffecte != reservation.nbPassager
 */
public void insert(Assignation assignation) throws SQLException {
    String sql = "INSERT INTO assignation (idVehicule, idReservation, nbPassagerAffecte, decalee) "
               + "VALUES (?, ?, ?, ?)";
    try (PreparedStatement pst = connection.prepareStatement(sql)) {
        pst.setInt(1, assignation.getIdVehicule());
        pst.setInt(2, assignation.getIdReservation());
        pst.setInt(3, assignation.getNbPassagerAffecte());  // NEW
        pst.setBoolean(4, assignation.isDecalee());
        pst.executeUpdate();
    }
}
```

### 3.2 Méthode `findByDate()`

```java
/**
 * Retourne toutes les assignations liées aux réservations d'une date donnée.
 */
public List<Assignation> findByDate(String date) throws SQLException {
    List<Assignation> assignations = new ArrayList<>();
    String sql = "SELECT a.id, a.idVehicule, a.idReservation, a.nbPassagerAffecte, a.decalee, a.datePlanification "
               + "FROM assignation a "
               + "JOIN reservation r ON a.idReservation = r.id "
               + "WHERE DATE(r.dateArrivee) = ? "
               + "ORDER BY a.datePlanification";
    try (PreparedStatement pst = connection.prepareStatement(sql)) {
        pst.setString(1, date);
        try (ResultSet rs = pst.executeQuery()) {
            while (rs.next()) {
                Assignation a = new Assignation();
                a.setId(rs.getInt("id"));
                a.setIdVehicule(rs.getInt("idVehicule"));
                a.setIdReservation(rs.getInt("idReservation"));
                a.setNbPassagerAffecte(rs.getInt("nbPassagerAffecte"));  // NEW
                a.setDecalee(rs.getBoolean("decalee"));
                a.setDatePlanification(rs.getString("datePlanification"));
                assignations.add(a);
            }
        }
    }
    return assignations;
}
```

### 3.3 Autres méthodes (`findById()`, `findAll()`, `update()`)

Appliquer le même pattern : ajouter `nbPassagerAffecte` dans les SELECT et le mapping ResultSet.

Exemple pour `findAll()` :

```java
public List<Assignation> findAll() throws SQLException {
    List<Assignation> assignations = new ArrayList<>();
    String sql = "SELECT id, idVehicule, idReservation, nbPassagerAffecte, decalee, datePlanification "
               + "FROM assignation "
               + "ORDER BY datePlanification DESC";
    try (Statement st = connection.createStatement()) {
        try (ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Assignation a = new Assignation();
                a.setId(rs.getInt("id"));
                a.setIdVehicule(rs.getInt("idVehicule"));
                a.setIdReservation(rs.getInt("idReservation"));
                a.setNbPassagerAffecte(rs.getInt("nbPassagerAffecte"));
                a.setDecalee(rs.getBoolean("decalee"));
                a.setDatePlanification(rs.getString("datePlanification"));
                assignations.add(a);
            }
        }
    }
    return assignations;
}
```

- [ ] Adapter `insert()` avec le paramètre `nbPassagerAffecte`
- [ ] Adapter `findByDate()` avec le mapping
- [ ] Adapter `findById()` avec le mapping
- [ ] Adapter `findAll()` avec le mapping
- [ ] Adapter `update()` (si elle existe) avec le mapping

---

## 4. Adapter `PlanningDao` — Logique de fractionnement (CŒUR)

Fichier : `src/main/java/dao/PlanningDao.java`

### 4.1 Classe interne `ReservationAffectee` (NEW)

Cette classe représente une **fraction d'une réservation** assignée à un véhicule.

Ajouter dans la classe `PlanningDao` :

```java
/**
 * Classe interne pour tracker une fraction de réservation assignée.
 * Permet de gérer le fractionnement : une réservation peut être divisée sur plusieurs véhicules.
 * Chaque fraction créera une ligne separate dans la table assignation.
 */
private static class ReservationAffectee {
    private Reservation reservation;
    private int nbPassagerAffecte;  // nombre réel assigné à cette fraction

    public ReservationAffectee(Reservation reservation, int nbPassagerAffecte) {
        this.reservation = reservation;
        this.nbPassagerAffecte = nbPassagerAffecte;
    }

    public Reservation getReservation() {
        return reservation;
    }

    public int getNbPassagerAffecte() {
        return nbPassagerAffecte;
    }
}
```

### 4.2 Méthode `assignerFraction()` (NEW)

Ajouter dans `PlanningDao` :

```java
/**
 * Assigne une fraction de réservation à un véhicule.
 * Cette méthode est appelée pour CHAQUE fraction (en cas de fractionnement).
 *
 * @param assignationsVol map idVehicule -> liste de fractions
 * @param placesRestantes map idVehicule -> places encore disponibles
 * @param vehiculeChoisiId id du véhicule recevant la fraction
 * @param reservation la réservation parente (peut être fractionnée)
 * @param nbPassagersAffectes nombre de passagers de cette fraction
 */
private void assignerFraction(
        Map<Integer, List<ReservationAffectee>> assignationsVol,
        Map<Integer, Integer> placesRestantes,
        Integer vehiculeChoisiId,
        Reservation reservation,
        int nbPassagersAffectes) {
    // Initialiser la liste pour ce véhicule s'il ne l'est pas déjà
    if (!assignationsVol.containsKey(vehiculeChoisiId)) {
        assignationsVol.put(vehiculeChoisiId, new ArrayList<>());
    }

    // Ajouter la fraction à la liste du véhicule
    assignationsVol.get(vehiculeChoisiId)
            .add(new ReservationAffectee(reservation, nbPassagersAffectes));

    // Décrémenter les places restantes du véhicule
    placesRestantes.put(
            vehiculeChoisiId,
            placesRestantes.get(vehiculeChoisiId) - nbPassagersAffectes
    );
}
```

### 4.3-4.5 Adapter les signatures

Les 3 méthodes doivent utiliser `Map<Integer, List<ReservationAffectee>>` au lieu de `Map<Integer, List<Reservation>>` :

```java
private Integer chercherVehiculeDejaUtilise(
        Map<Integer, List<ReservationAffectee>> assignationsVol,
        Map<Integer, Integer> placesRestantes,
        int nbPassagers,
        List<Vehicule> vehicules,
        Map<Integer, Integer> trajetsParVehicule)

private Integer chercherNouveauVehicule(
        Map<Integer, List<ReservationAffectee>> assignationsVol,
        Map<Integer, Integer> placesRestantes,
        int nbPassagers,
        List<Vehicule> vehicules,
        Map<Integer, Integer> trajetsParVehicule)

private void creerTrajetsPourVol(
        String heureVol,
        Map<Integer, List<ReservationAffectee>> assignationsVol,
        List<Vehicule> vehicules,
        double vitesseMoyenne,
        Map<Integer, String> vehiculeHeureRetour,
        List<Map<String, Object>> trajets,
        String groupeHeure)
```

La logique interne reste identique, on change juste le type passé en paramètre.

### 4.6 Variable locale

Dans `planifier()`, utiliser :

```java
Map<Integer, List<ReservationAffectee>> assignationsPassage = new LinkedHashMap<>();
```

### 4.7 Bloc métier : fractionnement (CŒUR)

Remplacer la boucle `for (Reservation r : nonAssigneesGroupe)` par :

```java
int reste = r.getNbPassager();  // nombre de passagers non encore assignés

// ÉTAPE 1 : essayer une assignation complète
Integer vehiculeChoisi = chercherVehiculeDejaUtilise(assignationsPassage, placesRestantes, reste, vehicules, trajetsParVehicule);
if (vehiculeChoisi == null) {
    vehiculeChoisi = chercherNouveauVehicule(assignationsPassage, placesRestantes, reste, vehicules, trajetsParVehicule);
}

if (vehiculeChoisi != null) {
    // Assignation complète possible
    assignerFraction(assignationsPassage, placesRestantes, vehiculeChoisi, r, reste);
    assignationDao.insert(new Assignation(vehiculeChoisi, r.getId(), reste, r.isDecalee()));
    reste = 0;  // tout est assigné
}

// ÉTAPE 2 : si reste > 0, fractionner sur les véhicules dispo (places DESC)
if (reste > 0) {
    // Trier les véhicules par places restantes (DESC)
    List<Integer> vehiculesDispoParPlaces = placesRestantes.entrySet().stream()
            .filter(e -> e.getValue() > 0)
            .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))  // DESC
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());

    for (Integer vehiculeId : vehiculesDispoParPlaces) {
        if (reste <= 0) break;

        int libre = placesRestantes.get(vehiculeId);
        int qte = Math.min(reste, libre);

        assignerFraction(assignationsPassage, placesRestantes, vehiculeId, r, qte);
        assignationDao.insert(new Assignation(vehiculeId, r.getId(), qte, r.isDecalee()));

        reste -= qte;
    }
}

// ÉTAPE 3 : si reliquat, reporter au groupe suivant
if (reste > 0) {
    // Créer une nouvelle réservation pour le reliquat
    Reservation reliquat = new Reservation();
    reliquat.setNbPassager(reste);
    reliquat.setDateArrivee(r.getDateArrivee());
    reliquat.setDecalee(true);  // marquer comme décalée
    // ... copier les autres champs de r

    encoreNonAssignees.add(reliquat);
}
```

> **Note** : le `reste` final peut être > 0 si aucun véhicule n'a de place disponible.
> Dans ce cas, la réservation es partiellement ou totalement non assignée.

- [ ] Ajouter la classe `ReservationAffectee`
- [ ] Ajouter la méthode `assignerFraction()`
- [ ] Adapter les signatures de `chercherVehiculeDejaUtilise()`, `chercherNouveauVehicule()`, `creerTrajetsPourVol()`
- [ ] Remplacer la variable `assignationsPassage`
- [ ] Implémenter le bloc de fractionnement dans la boucle `nonAssigneesGroupe`
- [ ] Vérifier que `ReservationAffectee` est utilisé correctement dans `creerTrajetsPourVol()`

---

## 5. Mettre à jour la vue `planningResult.jsp`

Fichier : `src/main/webapp/WEB-INF/views/planningResult.jsp`

**Objectif** : afficher le nombre réel de passagers assignés (via `nbPassagerAffecte`).

**Solution simple** : dans `creerTrajetsPourVol()`, créer une map `Map<Integer, Integer> qteParReservation` (idReservation → totalAssigné) et la passer à la vue.

En JSP, afficher :

```jsp
<%
    Map<Integer, Integer> qteParReservation = (Map<Integer, Integer>) ligne.get("qteParReservation");
    int qteAffectee = (qteParReservation != null && qteParReservation.containsKey(r.getId()))
        ? qteParReservation.get(r.getId())
        : r.getNbPassager();
%>
<span class="badge badge-purple"><%= qteAffectee %> pass.</span>
<%
    if (qteAffectee < r.getNbPassager()) {
%>
    <span class="badge badge-warning">Fraction</span>
<%
    }
%>
```

- [ ] Finir la logique dans `creerTrajetsPourVol()` pour passer la map des quantités
- [ ] Afficher `qteParReservation` en lieu et place de `r.getNbPassager()`
- [ ] Ajouter un badge "Fraction" si qteAffectee < nbPassager total

---

## Résumé des fichiers à créer/modifier

| Fichier                                           | Action     | Détail                                                |
|---------------------------------------------------|------------|-------------------------------------------------------|
| `script/20260318/db_20260318_sprint7.sql`         | **Créer**  | Ajouter colonne `nbPassagerAffecte` (dev/staging/prod) |
| `src/main/java/model/Assignation.java`            | **Modifier**| Ajouter champ `nbPassagerAffecte`                     |
| `src/main/java/dao/AssignationDao.java`           | **Modifier**| Adapter SQL et mapping ResultSet                      |
| `src/main/java/dao/PlanningDao.java`              | **Modifier**| Ajouter fractionnement logique (CŒUR)                |
| `src/main/webapp/WEB-INF/views/planningResult.jsp`| **Modifier**| Afficher `nbPassagerAffecte` par fraction              |

---

## Critères de validation

### Règles conservées (ne pas régresser)

- [ ] Un véhicule peut toujours transporter **plusieurs réservations complètes** (places partagées)
- [ ] Les réservations sont triées par `nbPassager DESC` au sein de chaque groupe
- [ ] La disponibilité par `heureRetour` fonctionne correctement
- [ ] Le choix du véhicule par "moins de trajets" puis "priorité carburant" fonctionne
- [ ] La boucle interne (véhicules qui reviennent dans la fenêtre) fonctionne
- [ ] Les réservations décalées affichent le tag "DÉCALÉE"

### Nouvelles règles Sprint 7

- [ ] **Cas simple : 23 → 10+8+5**
  - Réservation R=23 passagers
  - Véhicules : V1=10, V2=8, V3=6 places
  - Résultat attendu : 3 lignes assignation pour R
    - assignation(V1, R, nbPassagerAffecte=10)
    - assignation(V2, R, nbPassagerAffecte=8)
    - assignation(V3, R, nbPassagerAffecte=5)

- [ ] **Cas PO : fractionnement avec reliquat**
  - V1=8, V2=3 places libres
  - R1=6, R2=4, R3=3 à assigner
  - Résultat attendu :
    - V1 : R1(6) complète
    - V1 reste 2 places → R2 fraction(2)
    - V2 : R2 fraction(2) → reste 1 place
    - V2 : R3 fraction(1) → reste 0 place
    - Reliquat R3=2 reporté au groupe suivant (decalee=true)

- [ ] **Fin de journée : reliquat dans nonAssignees**
  - Si une réservation reste partiellement non assignée après le **dernier groupe**
  - Elle doit être dans la liste `nonAssignees` en bas de la vue
  - Avec le flag `decalee=true`

- [ ] **Affichage fractionnement en UI**
  - Chaque fraction montre le nombre exact de passagers (`nbPassagerAffecte`)
  - Un badge "Fraction" signale si la réservation est divisée
  - Aucun doublonnage de réservation (une même R-id peut avoir plusieurs fractions)

- [ ] **Persistance en base**
  - Chaque fraction crée une ligne distinct dans `assignation`
  - Le champ `nbPassagerAffecte` contient le bon nombre
  - Pas d'erreur de contrainte CHECK

---

## Points d'attention

### ⚠️ Reliquat — éviter la boucle infinie

Quand on crée le reliquat `Reservation` :
1. Créer une **vraie nouvelle instance** (pas une modif de l'original)
2. Copier les champs clés : `nbPassager` (le reste), `dateArrivee`, autres infos métier
3. Poser `setDecalee(true)` explicitement
4. L'ajouter à `reservationsEnAttente` (sera traité au groupe suivant)

```java
if (reste > 0) {
    Reservation reliquat = new Reservation();
    reliquat.setNbPassager(reste);
    reliquat.setDateArrivee(r.getDateArrivee());
    reliquat.setDecalee(true);
    // copier les autres champs
    encoreNonAssignees.add(reliquat);
}
```

### ⚠️ Type de `assignationsVol`

AVANT : `Map<Integer, List<Reservation>>`
APRÈS : `Map<Integer, List<ReservationAffectee>>`

Vérifier que **toutes** les utilisations de cette map utilisent `ReservationAffectee`:
- Dans `creerTrajetsPourVol()` quand on itère dessus
- Dans `assignerFraction()` qui l'alimente
- Dans la vue quand on l'exploite

### ⚠️ Tri DESC des véhicules

Lors du fractionnement, trier les places disponibles en **décroissant** :

```java
.sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))  // DESC !
```

(Note : `b, a` et non `a, b`)

---

## Checklist implémentation

- [ ] SQL Sprint 7 créé et exécuté
- [ ] `Assignation.java` mis à jour (champ + constructeurs)
- [ ] `AssignationDao.java` mis à jour (SQL + mapping)
- [ ] `PlanningDao.java` mis à jour (ReservationAffectee, assignerFraction, fractionnement)
- [ ] `planningResult.jsp` mis à jour (affichage qte)
- [ ] Build : `mvn clean package -DskipTests`
- [ ] Tests unitaires (si disponibles) : `mvn test`
- [ ] Déploiement de validation

---

## Dépendances

> **Le Sprint 7 dépend de Sprint 6.** Vérifier que :
> - Le modèle `Assignation` existe
> - Le DAO `AssignationDao` est implémenté
> - La boucle interne dans `PlanningDao` fonctionne
> - Les tests de Spring 6 passent
>

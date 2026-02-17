# DEV 3383 — BO

## Page 1 : Entrée de la date

Créer une page simple dans le BO avec :

- [ ] Un champ de type `date`
- [ ] Un bouton **"Planifier"**

> Au clic sur le bouton, l'utilisateur est redirigé vers la page de résultats (Page 2).

---

## Récupérer les données nécessaires

Pour la date choisie, récupérer :

- [ ] La liste des **réservations du jour**
- [ ] La liste de **tous les véhicules**

---

## Règles métier d'assignation

> **Principe clé :** Un véhicule peut contenir **plusieurs réservations** dans un même trajet. Une réservation ne peut **jamais** être divisée — tous les passagers d'une même réservation doivent être dans le même véhicule.

### Regroupement des réservations

- [ ] Trier les réservations par **heure d'arrivée**
- [ ] Regrouper les réservations dont l'écart d'heure d'arrivée est inférieur ou égal au **temps d'attente toléré** (`tempsAttente` de la table `parametre`)
- [ ] Au sein d'un groupe, vérifier que la **somme des passagers** de toutes les réservations ne dépasse pas la capacité du véhicule (`nbPassager`)
- [ ] Ne **jamais diviser** une réservation : si l'ajout d'une réservation dépasse la capacité, elle ne rejoint pas ce groupe

### Assignation d'un véhicule à un groupe

Pour chaque groupe de réservations :

- [ ] Filtrer les véhicules disponibles dont la capacité (`nbPassager`) est **>=** à la somme des passagers du groupe
- [ ] **Trier** les véhicules candidats par :
    1. Capacité croissante (le plus petit véhicule qui peut contenir le groupe)
    2. En cas d'égalité de capacité, priorité au **Diesel**
    3. Si toujours égalité (plusieurs Diesel), choix **aléatoire**
- [ ] Si un véhicule est trouvé, l'assigner au groupe (le marquer comme occupé pour la plage horaire)
- [ ] Si **aucun** véhicule n'est trouvé, ajouter les réservations du groupe à la liste **"non assignée"**

---

## Implémenter la logique de distance (Greedy)

Pour chaque véhicule assigné, déterminer l'ordre de visite des lieux :

- [ ] Récupérer les distances entre les lieux des réservations du groupe
- [ ] Partir du point de départ et choisir à chaque étape la destination la **plus proche** non encore visitée
- [ ] Calculer la distance totale du trajet

---

## Calcul des heures de départ / retour

Pour chaque réservation assignée, calculer :

- [ ] `heureRetour` = `heureDepart` + (`distanceTotale` / `vitesseMoyenne`)

> Le temps d'attente sur place n'est pas obligatoire pour l'instant.

---

## Page 2 : Résultat de la planification

Afficher deux tableaux distincts :

- [ ] **Tableau 1 — Véhicules planifiés**
  - Colonnes : Véhicule | Réservations assignées | Heure départ | Heure retour
- [ ] **Tableau 2 — Réservations non assignées**
  - Lister les réservations pour lesquelles aucun véhicule n'a été trouvé

---

## Tests

- [ ] Tester avec la date précise fournie par le DEV 3389 pour valider l'algorithme
- [ ] Vérifier le bon calcul des heures
- [ ] Vérifier le comportement en cas de non-disponibilité

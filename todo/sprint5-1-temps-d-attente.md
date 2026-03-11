# DEV 3383 — TEMPS D'ATTENTE ET REGROUPEMENT

## Objectif

Améliorer l'algorithme de regroupement des réservations en utilisant le **temps d'attente** pour définir les groupes de vols.

---

## Règles de gestion du regroupement

### 1. Définition du temps d'attente

Le paramètre `tempsAttente` (en minutes) définit la **fenêtre de regroupement** des vols.

**Exemples avec `tempsAttente = 30 min` :**

| Vols | Heure de départ | Explication |
|------|-----------------|-------------|
| 08:00 seul | 08:00 | Pas d'autre vol dans les 30 min |
| 08:00 et 09:00 | 08:00 | 09:00 - 08:00 = 60 min > 30 min → 2 groupes séparés |
| 08:00 et 08:15 | **08:15** | 08:15 - 08:00 = 15 min ≤ 30 min → 1 groupe, départ = dernière heure |
| 08:00, 08:15, 08:20 | **08:20** | Tous dans les 30 min → 1 groupe, départ = 08:20 |

### 2. Règle de départ

> **Tous les véhicules d'un groupe partent à l'heure du DERNIER vol du groupe**

---

## Algorithme de regroupement

### Étape 1 : Trier les réservations par `dateArrivee ASC`

```
R1 (08:00) → R2 (08:15) → R3 (08:20) → R4 (09:00)
```

### Étape 2 : Regrouper par fenêtre de temps d'attente

```
Groupe 1 : [R1, R2, R3] → Heure départ = 08:20 (dernière heure)
Groupe 2 : [R4] → Heure départ = 09:00
```

### Étape 3 : Pour chaque groupe, trier par `nbPassager DESC`

```
Groupe 1 trié : [R2 (5 pass), R1 (3 pass), R3 (2 pass)]
```

### Étape 4 : Assigner les véhicules selon les règles

1. **Plus de passagers** traité en premier
2. **Plus petit véhicule** capable de contenir le groupe
3. **Priorité Diesel** en cas d'égalité de capacité 
4. **Aléatoire** si plusieurs Diesel de même capacité

---

## Tâches à réaliser

### Base de données

- [ ] Vérifier que la table `parametre` contient `tempsAttente`
- [ ] Ajouter des données de test avec différentes valeurs de `tempsAttente`

### Code Java (`PlanningDao.java`)

- [ ] Modifier `regrouperParVol()` pour utiliser `tempsAttente`
  - [ ] Prendre l'heure du **premier vol** du groupe comme référence
  - [ ] Ajouter au groupe si `|heureVol - heureRéférence| ≤ tempsAttente`
  - [ ] Définir l'heure de départ = **dernière heure** du groupe

- [ ] Modifier `planifier()` pour utiliser l'heure de départ du groupe

### Tri des réservations dans le groupe

- [ ] Trier par `nbPassager` **DESC** (le plus de passagers en premier)
- [ ] Traiter dans cet ordre pour l'assignation des véhicules

## Critères de validation

- [ ] Les réservations dans la fenêtre `tempsAttente` sont regroupées
- [ ] L'heure de départ = dernière heure du groupe
- [ ] Les réservations sont triées par `nbPassager DESC` dans chaque groupe
- [ ] Les véhicules sont assignés selon les règles (capacité, Diesel, aléatoire)
- [ ] Avec `tempsAttente = 0`, chaque réservation est un groupe séparé
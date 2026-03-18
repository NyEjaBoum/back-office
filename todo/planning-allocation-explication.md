# Explication de la planification (PlanningDao)

Ce document explique ce que fait l'algorithme de `PlanningDao.planifier(...)`.

## Objectif

Pour une date donnee, l'algorithme :
- assigne les reservations aux vehicules,
- autorise le fractionnement d'une reservation sur plusieurs vehicules,
- reporte les reliquats non servis,
- calcule les trajets (distance, ordre, heure retour),
- renvoie :
  - `trajets` (vehicules planifies),
  - `nonAssignees` (passagers restants).

## Regles principales

1. Les anciennes assignations de la date sont supprimees.
2. Les reservations sont traitees par groupe horaire.
3. Dans un groupe, les reservations sont triees par nombre de passagers decroissant.
4. Pour chaque reservation :
   - on tente d'abord une assignation complete sur un seul vehicule,
   - si impossible, on fractionne le reste sur les vehicules disponibles.
5. En fractionnement, l'ordre des vehicules est :
   - capacite totale decroissante (`getNbrPlace()`),
   - puis places restantes decroissantes,
   - puis id croissant.
6. Si un reliquat existe encore, il est marque `decalee=true` et reporte.

## Pourquoi le resultat de ton exemple est celui attendu

Donnees :
- V1 = 8 places
- V2 = 3 places
- R1 = 6 passagers
- R2 = 4 passagers
- R3 = 3 passagers

Tri reservations : R1, R2, R3.

### Etape 1: R1 = 6
- V1 peut prendre 6 d'un coup.
- Reste vehicules :
  - V1: 2 places
  - V2: 3 places

### Etape 2: R2 = 4
- Aucun vehicule seul ne peut prendre 4.
- Fractionnement par capacite totale DESC : V1 (8) avant V2 (3).
- V1 prend 2 (reste R2 = 2).
- V2 prend 2 (reste R2 = 0).

### Etape 3: R3 = 3
- Places restantes:
  - V1: 0
  - V2: 1
- V2 prend 1 (reste R3 = 2).
- R3 reliquat 2 devient non assignee (decalee).

## Resultat final attendu

- V1: R1=6, R2=2
- V2: R2=2, R3=1
- Non assigne: R3=2

## Remarque affichage JSP

La vue affiche maintenant les details de fraction avec :
- ID reservation (`R#...`)
- ID client (`C#...`)
- quantite affectee sur le vehicule
- indicateur `Fraction` si l'affecte < original
- indicateur `DECALEE` si reporte

# DEV 3390 — SPRINT 7 : FRACTIONNEMENT DES RÉSERVATIONS

## Objectif

## Gestion des véhicules retournés et réservations non assignées

### 1. Véhicule retourné avec réservations non assignées
- Quand un véhicule revient et qu'il y a des réservations non assignées, le véhicule doit prendre en charge ces réservations non assignées

### 2. Nouveau regroupement avec temps d'attente
- Quand le véhicule retourne, il effectue un **nouveau regroupement** et un **nouveau temps d'attente** commence
- **Exemple** : Si le véhicule a une capacité de 20 places et qu'il y a seulement 5 clients :
  - Le véhicule attend pendant le temps d'attente configuré
  - Si d'autres clients arrivent pendant ce temps, ils sont ajoutés au regroupement
  - Si aucun nouveau client n'arrive après le temps d'attente, le véhicule part même s'il n'est pas plein

### 3. Priorité aux réservations non assignées
- Lors d'un nouveau regroupement, les **réservations non assignées doivent être priorisées** par rapport aux nouvelles réservations

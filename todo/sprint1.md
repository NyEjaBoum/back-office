# Sprint 1 - CICD Naina

## Tables à créer
- Table `hotel` (id, nom)
- Table `reservation` (id, client_id (4 chiffres), nombre_passager, date_heure_arrivee, id_hotel FK)

## Back Office (BO)
- Formulaire pour insérer une réservation (pas de protection)
- Sélection du hotel via base (dropdown)
- Pas d'interface hotel, mais script insertion hotel
- Script d'insertion hotel

## Front Office (FO)
- Liste des réservations
- Filtre des réservations par date

## Architecture
- FO et BO utilisent une seule base
- FO n'attaque pas directement la base, mais appelle une API du BO

---

### Répartition des tâches

**Dev 3657 :**
- Liste FO des réservations
- Filtre FO par date

**Dev 3389 :**
- Script insertion hotel
- Formulaire BO pour insérer réservation
- Dropdown hotel dans formulaire réservation
- API BO pour exposer les réservations à FO

---


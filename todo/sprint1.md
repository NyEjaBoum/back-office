
## Back Office (BO) — Dev 3389

1. **Script insertion hotel**
	- Créer un script SQL pour insérer des hôtels dans la table `hotel`.
	- Ce script sera exécuté pour ajouter les hôtels de référence dans la base.

2. **Formulaire BO pour insérer réservation**
	- Créer une page Back Office (avec le framework maison) pour ajouter une réservation.
	- Champs : client_id (4 chiffres), nombre_passager, date_heure_arrivee, sélection d’un hôtel (dropdown).
	- Pas besoin de protection/authentification pour ce formulaire dans ce sprint.

3. **Dropdown hotel dans formulaire réservation**
	- Le champ hôtel du formulaire doit être un dropdown alimenté dynamiquement depuis la base (liste des hôtels).
	- Faire une requête pour récupérer tous les hôtels et remplir le dropdown.

4. **API BO pour exposer les réservations à FO**
	- Créer une API REST (ex: `/api/reservations`) qui retourne la liste des réservations (avec infos hôtel associées).
	- Cette API sera utilisée par le Front Office pour afficher les réservations.
	- Utiliser le framework de ton projet pour créer ce endpoint.

---



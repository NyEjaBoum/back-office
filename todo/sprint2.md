## Back Office (BO) — Dev 3383
1. **Gestion Vehicule (BO)**
	- Ajouter une table `vehicule`.
	- Champs :
		- `id`
		- `reference`
		- `nbrPlace`
		- `typeCarburant` : valeurs autorisées `D` (Diesel), `ES` (Essence), `H` (Hybride).
	- Créer une page Back Office (framework maison) :
		- Page liste des véhicules.
		- Bouton **Ajouter** (redirige vers un formulaire d’ajout).

2. **Protection appel API — liste réservations**
	- L’endpoint API de liste des réservations (ex: `GET /api/reservations`) doit être protégé par token.
	- Chaque appel API DOIT envoyer un token (par ex. via header `X-API-TOKEN`).
	- Côté serveur, à chaque appel :
		- Vérifier que le token existe.
		- Vérifier que le token n’est pas expiré.
		- Si token absent / invalide : refuser l’appel.
		- Si token expiré : refuser l’appel avec un message du type `token expire`.
		- Si token valide : retourner la liste des réservations.

3. **Préparation protection — table token + génération**
	- Créer table `token` :
		- `id`
		- `token`
		- `date_expiration`
	- Pas besoin d’interface BO pour gérer le token dans ce sprint.
	- Créer un `Main` (exécutable) qui permet de générer / régénérer un token et de mettre à jour la date d’expiration.

4. **Token dans configuration**
	- Mettre le token (ou la clé / secret de token) dans un fichier de configuration (ex: `src/main/resources/application.properties`).
	- Tous les appels API côté client doivent lire ce token depuis la configuration et l’envoyer systématiquement.
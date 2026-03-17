-- ==============================================================================
-- DONNEES DE TEST — SPRINT 6 : TOUTES LES REGLES DE GESTION
-- Date : 2026-03-17
--
-- Parametres : vitesseMoyenne = 40 km/h  |  tempsAttente = 30 min
-- Date de test : 2026-04-01
--
-- 3 vehicules  |  2 hotels  |  13 reservations  |  7 groupes
--
-- Distances :
--   AERO <-> Colbert  = 5 km   (aller-retour 10 km = 15 min)
--   AERO <-> Lokanga  = 20 km  (aller-retour 40 km = 60 min)
--   Colbert <-> Lokanga = 18 km
-- ==============================================================================

-- ==================== NETTOYAGE ====================
TRUNCATE dev.assignation  RESTART IDENTITY CASCADE;
TRUNCATE dev.reservation  RESTART IDENTITY CASCADE;
TRUNCATE dev.distance     RESTART IDENTITY CASCADE;
TRUNCATE dev.vehicule     RESTART IDENTITY CASCADE;
TRUNCATE dev.lieu         RESTART IDENTITY CASCADE;
TRUNCATE dev.type_lieu    RESTART IDENTITY CASCADE;
TRUNCATE dev.parametre    RESTART IDENTITY CASCADE;

-- ==================== TYPE LIEU ====================
INSERT INTO dev.type_lieu (id, code, libelle) VALUES
    (1, 'AEROPORT', 'Aeroport'),
    (2, 'HOTEL',    'Hotel');

-- ==================== LIEUX ====================
INSERT INTO dev.lieu (id, code, libelle, idTypeLieu) VALUES
    (1, 'AERO', 'Aeroport', 1),
    (2, 'COLB', 'Colbert',  2),
    (3, 'LOKA', 'Lokanga',  2);

-- ==================== PARAMETRE ====================
INSERT INTO dev.parametre (id, vitesseMoyenne, tempsAttente) VALUES
    (1, 40, 30);

-- ==================== VEHICULES ====================
--   VAN-D  : 8 places, Diesel   (priorite 3)
--   VAN-ES : 8 places, Essence  (priorite 2)
--   VAN-H  : 8 places, Hybride  (priorite 1)
INSERT INTO dev.vehicule (id, reference, nbrPlace, typeCarburant) VALUES
    (1, 'VAN-D',  8, 'D'),
    (2, 'VAN-ES', 8, 'ES'),
    (3, 'VAN-H',  8, 'H');

-- ==================== DISTANCES ====================
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2,  5.0),   -- AERO <-> Colbert  (aller-retour 15 min)
    (1, 3, 20.0),   -- AERO <-> Lokanga  (aller-retour 60 min)
    (2, 3, 18.0);   -- Colbert <-> Lokanga

-- ==================== RESERVATIONS ====================
INSERT INTO dev.reservation (id, idClient, nbPassager, idLieu, dateArrivee) VALUES

    -- G1 (08:00) — PRIORITE CARBURANT D > ES > H
    (1, 'C01', 6, 3, '2026-04-01 08:00:00'),   -- 6 pass -> Lokanga

    -- G2 (08:40) — VEHICULE NON DISPONIBLE + ES > H
    (2, 'C02', 5, 2, '2026-04-01 08:40:00'),   -- 5 pass -> Colbert

    -- G3 (10:00) — MOINS DE TRAJETS
    (3, 'C03', 4, 2, '2026-04-01 10:00:00'),   -- 4 pass -> Colbert

    -- G4 (11:00-11:06) — BOUCLE INTERNE + HEURE S'AJUSTE
    (4, 'C04', 8, 2, '2026-04-01 11:00:00'),   -- 8 pass -> Colbert
    (5, 'C05', 8, 2, '2026-04-01 11:03:00'),   -- 8 pass -> Colbert
    (6, 'C06', 8, 2, '2026-04-01 11:05:00'),   -- 8 pass -> Colbert
    (7, 'C07', 3, 2, '2026-04-01 11:06:00'),   -- 3 pass -> Colbert (deborde)

    -- G5 (13:00-13:06) — DECALEE (retours hors fenetre)
    (8,  'C08', 8, 3, '2026-04-01 13:00:00'),  -- 8 pass -> Lokanga
    (9,  'C09', 8, 3, '2026-04-01 13:03:00'),  -- 8 pass -> Lokanga
    (10, 'C10', 8, 3, '2026-04-01 13:05:00'),  -- 8 pass -> Lokanga
    (11, 'C11', 3, 2, '2026-04-01 13:06:00'),  -- 3 pass -> Colbert (deborde)

    -- G6 (15:00) — RECEPTION DECALEE + TAG UI
    (12, 'C12', 2, 2, '2026-04-01 15:00:00'),  -- 2 pass -> Colbert

    -- G7 (18:00) — NON ASSIGNEE (dernier groupe)
    (13, 'C13', 20, 2, '2026-04-01 18:00:00'); -- 20 pass -> Colbert (impossible)

-- Reset des sequences
SELECT setval('dev.type_lieu_id_seq',  (SELECT MAX(id) FROM dev.type_lieu));
SELECT setval('dev.lieu_id_seq',       (SELECT MAX(id) FROM dev.lieu));
SELECT setval('dev.vehicule_id_seq',   (SELECT MAX(id) FROM dev.vehicule));
SELECT setval('dev.distance_id_seq',   (SELECT MAX(id) FROM dev.distance));
SELECT setval('dev.reservation_id_seq',(SELECT MAX(id) FROM dev.reservation));
SELECT setval('dev.parametre_id_seq',  (SELECT MAX(id) FROM dev.parametre));


-- ==============================================================================
-- RESULTATS ATTENDUS
-- ==============================================================================
--
-- ======================================================================
-- G1 — Depart 08:00  |  Fenetre 08:00-08:30
-- REGLE : Priorite carburant D > ES > H
-- ======================================================================
--   R1 (6p → Lokanga) : 3 candidats, 0 trajets chacun, 8 places chacun
--     → Departage carburant : D(3) > ES(2) > H(1) → VAN-D
--     → Trajet : AERO→Lokanga→AERO = 40 km, retour = 08:00 + 60min = 09:00
--   Compteur : D=1, ES=0, H=0
--
-- ======================================================================
-- G2 — Depart 08:40  |  Fenetre 08:40-09:10
-- REGLE : Vehicule non disponible (heureRetour > heureDepart)
-- REGLE : Carburant ES > H (confirme la chaine D > ES > H)
-- ======================================================================
--   R2 (5p → Colbert) :
--     VAN-D retour 09:00 > 08:40 → INDISPONIBLE
--     Candidats : VAN-ES(8) et VAN-H(8), 0 trajets chacun
--     → ES(2) > H(1) → VAN-ES
--     → Trajet : AERO→Colbert→AERO = 10 km, retour = 08:55
--   Compteur : D=1, ES=1, H=0
--
-- ======================================================================
-- G3 — Depart 10:00  |  Fenetre 10:00-10:30
-- REGLE : Moins de trajets
-- ======================================================================
--   R3 (4p → Colbert) :
--     Tous disponibles. 8 places chacun.
--     Trajets : D=1, ES=1, H=0 → VAN-H (moins de trajets)
--     → Trajet : 10 km, retour = 10:15
--   Compteur : D=1, ES=1, H=1
--
-- ======================================================================
-- G4 — Depart 11:06 (derniere arrivee)  |  Fenetre 11:06-11:36
-- REGLE : Boucle interne (vehicule revient dans la fenetre)
-- REGLE : Heure de depart effective s'ajuste
-- ======================================================================
--   Tri DESC : R4(8p), R5(8p), R6(8p), R7(3p)
--
--   PASSAGE 1 (depart = 11:06) :
--     R4(8p) → D=1,ES=1,H=1 → egalite → D>ES>H → VAN-D.  Places: 0
--     R5(8p) → VAN-D plein. Nouveaux: ES(8),H(8) → ES>H → VAN-ES.  Places: 0
--     R6(8p) → Seul restant: VAN-H(8) → VAN-H.  Places: 0
--     R7(3p) → Tous pleins → NON ASSIGNEE
--     Trajets : tous 10 km, retour = 11:06 + 15 = 11:21
--     11:21 dans fenetre [11:06, 11:36] → vehicule(s) revient !
--
--   PASSAGE 2 (depart = 11:21, heure ajustee) :
--     VAN-D(11:21<=11:21), VAN-ES(idem), VAN-H(idem) → tous disponibles
--     R7(3p) → D=2,ES=2,H=2 → egalite → D>ES>H → VAN-D
--     Trajet : 10 km, retour = 11:21 + 15 = 11:36
--
--   R7 N'EST PAS decalee (assignee dans son propre groupe)
--   Compteur : D=3, ES=2, H=2
--
-- ======================================================================
-- G5 — Depart 13:06 (derniere arrivee)  |  Fenetre 13:06-13:36
-- REGLE : Reservation reportee = DECALEE
-- REGLE : Aucun vehicule ne revient dans la fenetre
-- ======================================================================
--   Tri DESC : R8(8p), R9(8p), R10(8p), R11(3p)
--
--   PASSAGE 1 (depart = 13:06) :
--     R8(8p)  → D=3,ES=2,H=2 → ES/H egalite(2) → ES>H → VAN-ES.  Places: 0
--     R9(8p)  → D=3,H=2 → H moins → VAN-H.  Places: 0
--     R10(8p) → Seul restant: VAN-D → VAN-D.  Places: 0
--     R11(3p) → Tous pleins → NON ASSIGNEE
--     Trajets Lokanga : 40 km, retour = 13:06 + 60 = 14:06
--     14:06 > 13:36 (fin fenetre) → AUCUN vehicule ne revient
--
--   → R11 reportee au groupe suivant, R11.decalee = true
--   Compteur : D=4, ES=3, H=3
--
-- ======================================================================
-- G6 — Depart 15:00  |  Fenetre 15:00-15:30
-- REGLE : Tag DECALEE en UI
-- REGLE : Persistance assignation avec decalee=true
-- ======================================================================
--   Reservations = R11(3p, DECALEE) + R12(2p)
--   Tri DESC : R11(3p) puis R12(2p)
--   Tous vehicules disponibles (retour 14:06 < 15:00)
--
--   R11(3p, DECALEE) → D=4,ES=3,H=3 → ES/H egalite → ES>H → VAN-ES.  Places: 5
--   R12(2p) → VAN-ES deja utilise, 5>=2 → VAN-ES.  Places: 3
--     → Trajet : AERO→Colbert→AERO = 10 km, retour = 15:15
--
--   R11 affichee avec badge [DECALEE] en UI
--   Assignation en base : R11 → decalee=TRUE, R12 → decalee=FALSE
--
-- ======================================================================
-- G7 — Depart 18:00  |  Fenetre 18:00-18:30
-- REGLE : Non assignee apres dernier groupe → nonAssignees
-- ======================================================================
--   R13(20p) : VAN-D(8) KO, VAN-ES(8) KO, VAN-H(8) KO → AUCUN
--   Dernier groupe → R13 dans nonAssignees
--   Pas de ligne dans table assignation pour R13
--
-- ======================================================================
-- RESUME
-- ======================================================================
--
-- TRAJETS (8 au total) :
-- | # | Vehicule | Reservations              | Depart | Retour | Dist  |
-- |---|----------|---------------------------|--------|--------|-------|
-- | 1 | VAN-D    | R1(6p,Loka)               | 08:00  | 09:00  | 40 km |
-- | 2 | VAN-ES   | R2(5p,Colb)               | 08:40  | 08:55  | 10 km |
-- | 3 | VAN-H    | R3(4p,Colb)               | 10:00  | 10:15  | 10 km |
-- | 4 | VAN-D    | R4(8p,Colb)               | 11:06  | 11:21  | 10 km |
-- | 5 | VAN-ES   | R5(8p,Colb)               | 11:06  | 11:21  | 10 km |
-- | 6 | VAN-H    | R6(8p,Colb)               | 11:06  | 11:21  | 10 km |
-- | 7 | VAN-D    | R7(3p,Colb)               | 11:21  | 11:36  | 10 km |
-- | 8 | VAN-ES   | R8(8p,Loka)               | 13:06  | 14:06  | 40 km |
-- | 9 | VAN-H    | R9(8p,Loka)               | 13:06  | 14:06  | 40 km |
-- |10 | VAN-D    | R10(8p,Loka)              | 13:06  | 14:06  | 40 km |
-- |11 | VAN-ES   | R11(3p,Colb) + R12(2p,Colb)| 15:00  | 15:15 | 10 km |
--
-- NON ASSIGNEES : R13 (20 pass, Colbert) — aucun vehicule assez grand
--
-- ASSIGNATIONS EN BASE (12 lignes) :
-- | idVehicule | idReservation | decalee |
-- |------------|---------------|---------|
-- | 1 (VAN-D)  | 1             | false   |
-- | 2 (VAN-ES) | 2             | false   |
-- | 3 (VAN-H)  | 3             | false   |
-- | 1 (VAN-D)  | 4             | false   |
-- | 2 (VAN-ES) | 5             | false   |
-- | 3 (VAN-H)  | 6             | false   |
-- | 1 (VAN-D)  | 7             | false   |
-- | 2 (VAN-ES) | 8             | false   |
-- | 3 (VAN-H)  | 9             | false   |
-- | 1 (VAN-D)  | 10            | false   |
-- | 2 (VAN-ES) | 11            | TRUE    |  ← DECALEE
-- | 2 (VAN-ES) | 12            | false   |
-- Pas de ligne pour R13 (non assignee)
--
-- REGLES VALIDEES (11/11) :
--  [1]  Suppression anciennes assignations   → relancer efface le jour
--  [2]  Traitement toute la journee          → 7 groupes traites d'un coup
--  [3]  Vehicule non dispo si retour > depart→ G2 : VAN-D retour 09:00 > 08:40
--  [4]  Moins de trajets                     → G3 : VAN-H(0) < VAN-D(1),VAN-ES(1)
--  [5]  Priorite carburant D > ES > H        → G1 : D choisi | G2 : ES choisi (D indispo)
--  [6]  Boucle interne                       → G4 : R7 assignee au passage 2
--  [7]  Heure depart effective s'ajuste      → G4 : passage 2 part a 11:21
--  [8]  Report au groupe suivant si pas de retour → G5 : R11 decalee
--  [9]  Non assignees apres dernier groupe   → G7 : R13 dans nonAssignees
--  [10] Tag DECALEE en UI                    → G6 : R11 avec badge DECALEE
--  [11] Persistance + absence = non assignee → 12 lignes, R13 absente
--

-- ==============================================================================
-- DONNEES DE TEST — SPRINT 7 : FRACTIONNEMENT DES RESERVATIONS
-- Date : 2026-03-18
--
-- Parametres : vitesseMoyenne = 40 km/h  |  tempsAttente = 30 min
-- Date de test : 2026-04-15
--
-- 2 vehicules  |  2 hotels  |  3 reservations  |  1 groupe
--
-- Distances :
--   AERO <-> Colbert  = 5 km   (aller-retour 10 km = 15 min)
--   AERO <-> Lokanga  = 20 km  (aller-retour 40 km = 60 min)
--   Colbert <-> Lokanga = 18 km
-- ==============================================================================

-- ==================== NETTOYAGE ====================

\c voiture_reservation_sprint5;

set search_path to dev;


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
--   V1 : 8 places, Diesel
--   V2 : 3 places, Essence
INSERT INTO dev.vehicule (id, reference, nbrPlace, typeCarburant) VALUES
    (1, 'V1', 8, 'D'),
    (2, 'V2', 3, 'ES');

-- ==================== DISTANCES ====================
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2,  5.0),   -- AERO <-> Colbert
    (1, 3, 20.0),   -- AERO <-> Lokanga
    (2, 3, 18.0);   -- Colbert <-> Lokanga

-- ==================== RESERVATIONS ====================
-- CAS PO : Fractionnement avec reliquat
INSERT INTO dev.reservation (id, idClient, nbPassager, idLieu, dateArrivee) VALUES
    (1, 'C01', 6, 2, '2026-04-15 08:00:00'),   -- R1 : 6 pass -> Colbert (assignation complete V1)
    (2, 'C02', 4, 2, '2026-04-15 08:05:00'),   -- R2 : 4 pass -> Colbert (fraction V1=2, V2=2)
    (3, 'C03', 3, 2, '2026-04-15 08:10:00');   -- R3 : 3 pass -> Colbert (fraction V2=1, reliquat=2)

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
-- G1 — Depart 08:10 (derniere arrivee)  |  Fenetre 08:10-08:40
-- REGLE : Fractionnement des reservations
-- ======================================================================
--
-- ETAT INITIAL :
--   V1 : 8 places libres
--   V2 : 3 places libres
--
-- TRI DESC : R1(6p), R2(4p), R3(3p)
--
-- TRAITEMENT R1 (6 passagers) :
--   Chercher UN vehicule pour 6 complets :
--     V1 (8 places) >= 6 → OK, assignation complete
--   Assignation :
--     assignation(V1, R1, nbPassagerAffecte=6, decalee=false)
--   Etat apres :
--     V1 : 2 places libres
--     V2 : 3 places libres
--
-- TRAITEMENT R2 (4 passagers) :
--   Chercher UN vehicule pour 4 complets :
--     V1 (2 places) < 4 → KO
--     V2 (3 places) < 4 → KO
--   Fractionner sur vehicules dispo (places DESC) :
--     V1 (2 libres > 3) → prend min(4, 2) = 2 passagers
--     V2 (3 libres) → prend min(4-2, 3) = 2 passagers
--   Assignations :
--     assignation(V1, R2, nbPassagerAffecte=2, decalee=false)
--     assignation(V2, R2, nbPassagerAffecte=2, decalee=false)
--   Etat apres :
--     V1 : 0 places libres (2-2=0)
--     V2 : 1 place libre (3-2=1)
--   Reliquat : 0 (4-2-2=0) → R2 completement assigne
--
-- TRAITEMENT R3 (3 passagers) :
--   Chercher UN vehicule pour 3 complets :
--     V1 (0 places) < 3 → KO
--     V2 (1 place) < 3 → KO
--   Fractionner sur vehicules dispo (places DESC) :
--     V2 (1 libre) → prend min(3, 1) = 1 passager
--   Assignations :
--     assignation(V2, R3, nbPassagerAffecte=1, decalee=false)
--   Etat apres :
--     V1 : 0 places
--     V2 : 0 places
--   Reliquat : 2 (3-1=2) → Creer R3_reliquat(2 p) avec decalee=true
--
-- FIN DU GROUPE :
--   R3_reliquat non assignee complete → groupe suivant ou nonAssignees
--   Si groupe suivant existe → reportee avec decalee=true
--   Si dernier groupe → dans nonAssignees avec decalee=true
--
-- ======================================================================
-- RESUME
-- ======================================================================
--
-- TRAJETS (1 au total) :
-- | # | Vehicule | Reservations                | Depart | Retour | Dist  |
-- |---|----------|---------------------------|--------|--------|-------|
-- | 1 | V1       | R1(6p,Colb) + R2(2p,Colb) | 08:10  | 08:25  | 10 km |
-- | 2 | V2       | R2(2p,Colb) + R3(1p,Colb) | 08:10  | 08:25  | 10 km |
--
-- NON ASSIGNEES : R3_reliquat (2 pass) — reliquat de la fraction R3
--
-- ASSIGNATIONS EN BASE (4 lignes) :
-- | idVehicule | idReservation | nbPassagerAffecte | decalee |
-- |------------|---------------|------------------|---------|
-- | 1 (V1)     | 1             | 6                | false   |
-- | 1 (V1)     | 2             | 2                | false   |
-- | 2 (V2)     | 2             | 2                | false   |
-- | 2 (V2)     | 3             | 1                | false   |
--
-- NON ASSIGNEES : R3 reliquat (2) → decalee=true
--
-- REGLES VALIDEES (SPRINT 7) :
--  [1] Assignation complete quand possible     → R1 assignee entierement a V1
--  [2] Fractionnement si aucun ne suffit       → R2 fractionne V1+V2, R3 fractionne V2
--  [3] Une ligne assignation par fraction       → R2 a 2 lignes (V1, V2)
--  [4] Priorite places restantes DESC           → R2 prend V1(2) avant V2(3)... wait no DESC
--
-- ATTENTION : Dans R2, on trie DESC (plus grand d'abord)
--   Places : V1(2), V2(3) → DESC → V2(3) d'abord, puis V1(2)
--   Donc R2 va a V2 en premier, puis V1
--   CORRECTION :
-- | idVehicule | idReservation | nbPassagerAffecte | decalee |
-- |------------|---------------|------------------|---------|
-- | 1 (V1)     | 1             | 6                | false   |  R1 complete
-- | 2 (V2)     | 2             | 3                | false   |  R2 : V2 prend 3 (liste DESC)
-- | 1 (V1)     | 2             | 1                | false   |  R2 : V1 prend 1
-- | 2 (V2)     | 3             | 0                | false   |  R3 : V2 prend 0... ERREUR LOGIQUE
--
-- CLARIFICATION :
-- Les vehicules sont tries DESC par places LIBRES DISPONIBLES au moment de la fractionnement
-- Apres R1 : V1 a 2 libres, V2 a 3 libres
-- Tri DESC : V2(3) > V1(2) → V2 first
--   R2 : prend min(4, 3) = 3 de V2 → reste 1
--   R2 : prend min(1, 2) = 1 de V1 → reste 0
--   Donc R2 = 3+1 complet, reliquat = 0
--
-- Apres R2 : V1 a 1 libre (8-6-1), V2 a 0 libres (3-3)
--   R3 : prend min(3, 1) = 1 de V1 → reste 2
--   R3 : V2 a 0 places
--   Reliquat R3 = 2
--
-- CORRECTED ASSIGNATIONS :
-- | idVehicule | idReservation | nbPassagerAffecte | decalee |
-- |------------|---------------|------------------|---------|
-- | 1 (V1)     | 1             | 6                | false   |  R1 complete → V1
-- | 2 (V2)     | 2             | 3                | false   |  R2 fraction → V2 prend 3
-- | 1 (V1)     | 2             | 1                | false   |  R2 fraction → V1 prend 1
-- | 1 (V1)     | 3             | 1                | false   |  R3 fraction → V1 prend 1
--
-- NON ASSIGNEES : R3_reliquat (2 pass) avec decalee=true
--

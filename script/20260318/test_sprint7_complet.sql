-- ==============================================================================
-- DONNEES DE TEST COMPLETES — SPRINT 7 : FRACTIONNEMENT DES RESERVATIONS
-- Date : 2026-03-18
--
-- Parametres : vitesseMoyenne = 40 km/h  |  tempsAttente = 30 min
-- Date de test : 2026-04-20
--
-- 5 vehicules  |  4 hotels  |  12 reservations  |  3 groupes horaires
--
-- Distances :
--   AERO <-> Colbert  = 5 km   (aller-retour 10 km = 15 min)
--   AERO <-> Lokanga  = 20 km  (aller-retour 40 km = 60 min)
--   AERO <-> Carlton  = 8 km   (aller-retour 16 km = 24 min)
--   AERO <-> Ibis     = 12 km  (aller-retour 24 km = 36 min)
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
    (3, 'LOKA', 'Lokanga',  2),
    (4, 'CARL', 'Carlton',  2),
    (5, 'IBIS', 'Ibis',     2);

-- ==================== PARAMETRE ====================
INSERT INTO dev.parametre (id, vitesseMoyenne, tempsAttente) VALUES
    (1, 40, 30);

-- ==================== VEHICULES ====================
--   V1 : 18 places, Diesel
--   V2 : 8 places, Essence
--   V3 : 6 places, Hybride
--   V4 : 3 places, Diesel
--   V5 : 5 places, Essence
INSERT INTO dev.vehicule (id, reference, nbrPlace, typeCarburant) VALUES
    (1, 'V1', 18, 'D'),
    (2, 'V2', 8,  'ES'),
    (3, 'V3', 6,  'H'),
    (4, 'V4', 3,  'D'),
    (5, 'V5', 5,  'ES');

-- ==================== DISTANCES ====================
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2,  5.0),   -- AERO <-> Colbert
    (1, 3, 20.0),   -- AERO <-> Lokanga
    (1, 4,  8.0),   -- AERO <-> Carlton
    (1, 5, 12.0),   -- AERO <-> Ibis
    (2, 3, 18.0),   -- Colbert <-> Lokanga
    (2, 4,  6.0),   -- Colbert <-> Carlton
    (2, 5, 10.0),   -- Colbert <-> Ibis
    (3, 4, 15.0),   -- Lokanga <-> Carlton
    (3, 5, 10.0),   -- Lokanga <-> Ibis
    (4, 5,  7.0);   -- Carlton <-> Ibis

-- ==================== RESERVATIONS ====================
-- CAS 1 : GROUPE 08:00-08:30 (4 reservations)
-- Tri DESC : R1(23), R2(10), R3(7), R4(4)
INSERT INTO dev.reservation (id, idClient, nbPassager, idLieu, dateArrivee) VALUES
    (1,  'C01', 23, 2, '2026-04-20 08:00:00'),  -- R1 : 23 pass -> Colbert (fractionnement obligatoire)
    (2,  'C02', 10, 3, '2026-04-20 08:05:00'),  -- R2 : 10 pass -> Lokanga
    (3,  'C03',  7, 4, '2026-04-20 08:10:00'),  -- R3 : 7 pass -> Carlton
    (4,  'C04',  4, 5, '2026-04-20 08:15:00'),  -- R4 : 4 pass -> Ibis

-- CAS 2 : GROUPE 10:00-10:30 (4 reservations)
-- Tri DESC : R5(12), R6(8), R7(5), R8(3)
    (5,  'C05', 12, 2, '2026-04-20 10:00:00'),  -- R5 : 12 pass -> Colbert
    (6,  'C06',  8, 3, '2026-04-20 10:10:00'),  -- R6 : 8 pass -> Lokanga
    (7,  'C07',  5, 4, '2026-04-20 10:15:00'),  -- R7 : 5 pass -> Carlton
    (8,  'C08',  3, 5, '2026-04-20 10:20:00'),  -- R8 : 3 pass -> Ibis

-- CAS 3 : GROUPE 14:00-14:30 (4 reservations)
-- Tri DESC : R9(15), R10(9), R11(6), R12(2)
    (9,  'C09', 15, 2, '2026-04-20 14:00:00'),  -- R9 : 15 pass -> Colbert
    (10, 'C10',  9, 3, '2026-04-20 14:05:00'),  -- R10 : 9 pass -> Lokanga
    (11, 'C11',  6, 4, '2026-04-20 14:10:00'),  -- R11 : 6 pass -> Carlton
    (12, 'C12',  2, 5, '2026-04-20 14:20:00');  -- R12 : 2 pass -> Ibis

-- Reset des sequences
SELECT setval('dev.type_lieu_id_seq',  (SELECT MAX(id) FROM dev.type_lieu));
SELECT setval('dev.lieu_id_seq',       (SELECT MAX(id) FROM dev.lieu));
SELECT setval('dev.vehicule_id_seq',   (SELECT MAX(id) FROM dev.vehicule));
SELECT setval('dev.distance_id_seq',   (SELECT MAX(id) FROM dev.distance));
SELECT setval('dev.reservation_id_seq',(SELECT MAX(id) FROM dev.reservation));
SELECT setval('dev.parametre_id_seq',  (SELECT MAX(id) FROM dev.parametre));


-- ==============================================================================
-- RESULTATS ATTENDUS AVEC LA NOUVELLE LOGIQUE
-- ==============================================================================
--
-- ======================================================================
-- GROUPE 1 — Depart 08:15 (derniere arrivee R4)  |  Fenetre 08:15-08:45
-- ======================================================================
--
-- VEHICULES DISPONIBLES :
--   V1 : 18 places, Diesel
--   V2 : 8 places, Essence
--   V3 : 6 places, Hybride
--   V4 : 3 places, Diesel
--   V5 : 5 places, Essence
--
-- TRI DESC : R1(23p), R2(10p), R3(7p), R4(4p)
--
-- TRAITEMENT R1 (23 passagers) :
--   1. Chercher déjà utilisé : aucun
--   2. Chercher nouveau avec places >= 23 : aucun (V1 max=18)
--   3. Fractionnement - chercher nouveau avec plus de places : V1(18) le plus grand
--      → V1 prend 18, reste 5
--   4. Reste 5 : chercher déjà utilisé : V1(0) ❌
--   5. Chercher nouveau avec places >= 5 : V2(8), V3(6), V5(5)
--      → V5(5) a le moins de places pour 5 → V5 prend 5, reste 0
--   Assignations : V1(18), V5(5)
--   Etat : V1=0, V2=8, V3=6, V4=3, V5=0
--
-- TRAITEMENT R2 (10 passagers) :
--   1. Chercher déjà utilisé avec places >= 10 : aucun
--   2. Chercher nouveau avec places >= 10 : aucun
--   3. Fractionnement - chercher nouveau plus grand : V2(8)
--      → V2 prend 8, reste 2
--   4. Reste 2 : chercher déjà utilisé : V1(0), V5(0) ❌
--   5. Chercher nouveau avec places >= 2 : V3(6), V4(3)
--      → V4(3) a le moins de places >= 2 → V4 prend 2, reste 0
--   Assignations : V2(8), V4(2)
--   Etat : V1=0, V2=0, V3=6, V4=1, V5=0
--
-- TRAITEMENT R3 (7 passagers) :
--   1. Chercher déjà utilisé avec places >= 7 : aucun
--   2. Chercher nouveau avec places >= 7 : aucun
--   3. Fractionnement - chercher nouveau plus grand : V3(6)
--      → V3 prend 6, reste 1
--   4. Reste 1 : chercher déjà utilisé : V4(1) ✓
--      → V4 déjà utilisé prioritaire, V4 prend 1, reste 0
--   Assignations : V3(6), V4(1)
--   Etat : V1=0, V2=0, V3=0, V4=0, V5=0
--
-- TRAITEMENT R4 (4 passagers) :
--   1. Tous les véhicules sont pleins
--   → Reliquat R4(4) avec decalee=true reporté au groupe suivant
--
-- ======================================================================
-- GROUPE 2 — Depart 10:20 (derniere arrivee R8)  |  Fenetre 10:20-10:50
-- AVEC R4 décalée du groupe 1
-- ======================================================================
--
-- TRI DESC : R5(12p), R6(8p), R7(5p), R8(3p), R4_decalee(4p)
--
-- TRAITEMENT R5 (12 passagers) :
--   Nouveau : V1(18) >= 12 → V1 prend 12
--   Etat : V1=6, V2=8, V3=6, V4=3, V5=5
--
-- TRAITEMENT R6 (8 passagers) :
--   Déjà utilisé : V1(6) < 8
--   Nouveau : V2(8) = 8 → V2 prend 8
--   Etat : V1=6, V2=0, V3=6, V4=3, V5=5
--
-- TRAITEMENT R7 (5 passagers) :
--   Déjà utilisé : V1(6) >= 5, V2(0)
--   → V1 a le moins de places pour 5 → V1 prend 5
--   Etat : V1=1, V2=0, V3=6, V4=3, V5=5
--
-- TRAITEMENT R8 (3 passagers) :
--   Déjà utilisé : V1(1) < 3, V2(0)
--   Nouveau : V3(6), V4(3), V5(5)
--   → V4(3) a le moins de places pour 3 → V4 prend 3
--   Etat : V1=1, V2=0, V3=6, V4=0, V5=5
--
-- TRAITEMENT R4_decalee (4 passagers) :
--   Déjà utilisé : V1(1) < 4
--   Nouveau : V3(6), V5(5)
--   → V5(5) a le moins de places pour 4 → V5 prend 4
--   Etat : V1=1, V2=0, V3=6, V4=0, V5=1
--
-- ======================================================================
-- GROUPE 3 — Depart 14:20 (derniere arrivee R12)  |  Fenetre 14:20-14:50
-- ======================================================================
--
-- TRI DESC : R9(15p), R10(9p), R11(6p), R12(2p)
--
-- TRAITEMENT R9 (15 passagers) :
--   Nouveau : V1(18) >= 15 → V1 prend 15
--   Etat : V1=3, V2=8, V3=6, V4=3, V5=5
--
-- TRAITEMENT R10 (9 passagers) :
--   Déjà utilisé : V1(3) < 9
--   Nouveau : V2(8) < 9
--   Fractionnement nouveau plus grand : V2(8) → V2 prend 8, reste 1
--   Reste 1 : déjà utilisé V1(3) >= 1 → V1 prend 1
--   Etat : V1=2, V2=0, V3=6, V4=3, V5=5
--
-- TRAITEMENT R11 (6 passagers) :
--   Déjà utilisé : V1(2) < 6, V2(0)
--   Nouveau : V3(6) = 6 → V3 prend 6
--   Etat : V1=2, V2=0, V3=0, V4=3, V5=5
--
-- TRAITEMENT R12 (2 passagers) :
--   Déjà utilisé : V1(2) = 2 → V1 prend 2
--   Etat : V1=0, V2=0, V3=0, V4=3, V5=5
--
-- ======================================================================
-- RESUME DES ASSIGNATIONS ATTENDUES
-- ======================================================================
--
-- GROUPE 1 (08:15) :
-- | Vehicule | Reservations                 | Places utilisées |
-- |----------|------------------------------|------------------|
-- | V1       | R1(18/23)                    | 18/18            |
-- | V5       | R1(5/23)                     | 5/5              |
-- | V2       | R2(8/10)                     | 8/8              |
-- | V4       | R2(2/10) + R3(1/7)           | 3/3              |
-- | V3       | R3(6/7)                      | 6/6              |
-- NON ASSIGNEES : R4(4) décalée
--
-- GROUPE 2 (10:20) :
-- | Vehicule | Reservations                 | Places utilisées |
-- |----------|------------------------------|------------------|
-- | V1       | R5(12) + R7(5)               | 17/18            |
-- | V2       | R6(8)                        | 8/8              |
-- | V4       | R8(3)                        | 3/3              |
-- | V5       | R4_decalee(4)                | 4/5              |
--
-- GROUPE 3 (14:20) :
-- | Vehicule | Reservations                 | Places utilisées |
-- |----------|------------------------------|------------------|
-- | V1       | R9(15) + R10(1/9) + R12(2)   | 18/18            |
-- | V2       | R10(8/9)                     | 8/8              |
-- | V3       | R11(6)                       | 6/6              |
--
-- ASSIGNATIONS EN BASE (21 lignes) :
-- | idVehicule | idReservation | nbPassagerAffecte | decalee |
-- |------------|---------------|-------------------|---------|
-- | 1          | 1             | 18                | false   |
-- | 5          | 1             | 5                 | false   |
-- | 2          | 2             | 8                 | false   |
-- | 4          | 2             | 2                 | false   |
-- | 3          | 3             | 6                 | false   |
-- | 4          | 3             | 1                 | false   |
-- | 1          | 5             | 12                | false   |
-- | 2          | 6             | 8                 | false   |
-- | 1          | 7             | 5                 | false   |
-- | 4          | 8             | 3                 | false   |
-- | 5          | 4             | 4                 | true    |  -- R4 décalée
-- | 1          | 9             | 15                | false   |
-- | 2          | 10            | 8                 | false   |
-- | 1          | 10            | 1                 | false   |
-- | 3          | 11            | 6                 | false   |
-- | 1          | 12            | 2                 | false   |
--
-- TOUTES les réservations sont assignées !
--

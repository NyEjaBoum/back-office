-- ==============================================================================
-- DONNEES DE TEST — SCENARIO SPRINT 8
-- Date : 2026-03-26
--
-- Parametres : vitesseMoyenne = 50 km/h  |  tempsAttente = 30 min
-- Date de test : 2026-03-19
--
-- 5 vehicules  |  2 hotels  |  6 reservations
--
-- Distances :
--   AERO <-> hotel1  = 90 km
--   AERO <-> hotel2  = 35 km
--   hotel1 <-> hotel2 = 60 km
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
    (1, 'AERO',   'Aeroport', 1),
    (2, 'HOTEL1', 'Hotel1',   2),
    (3, 'HOTEL2', 'Hotel2',   2);

-- ==================== PARAMETRE ====================
INSERT INTO dev.parametre (id, vitesseMoyenne, tempsAttente) VALUES
    (1, 50, 30);

-- ==================== VEHICULES ====================
--   V1 : 5 places, Diesel, dispo dès 00:00
--   V2 : 5 places, Essence, dispo dès 00:00
--   V3 : 12 places, Diesel, dispo dès 00:00
--   V4 : 9 places, Diesel, dispo dès 00:00
--   V5 : 12 places, Essence, dispo dès 13:00
INSERT INTO dev.vehicule (id, reference, nbrPlace, typeCarburant, heureDisponibilite) VALUES
    (1, 'V1', 5,  'D',  '2026-03-19 09:00:00'),
    (2, 'V2', 5,  'ES', '2026-03-19 09:00:00'),
    (3, 'V3', 12, 'D',  '2026-03-19 00:00:00'),
    (4, 'V4', 9,  'D',  '2026-03-19 09:00:00'),
    (5, 'V5', 12, 'ES', '2026-03-19 13:00:00');

-- ==================== DISTANCES ====================
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 90.0),   -- AERO <-> Hotel1
    (1, 3, 35.0),   -- AERO <-> Hotel2
    (2, 3, 60.0);   -- Hotel1 <-> Hotel2

-- ==================== RESERVATIONS ====================
-- Client1 : 7 passagers -> Hotel1, arrive 00:00
-- Client2 : 20 passagers -> Hotel2, arrive 08:00
-- Client3 : 3 passagers -> Hotel1, arrive 09:10
-- Client4 : 10 passagers -> Hotel1, arrive 09:15
-- Client5 : 5 passagers -> Hotel1, arrive 09:20
-- Client6 : 12 passagers -> Hotel1, arrive 13:30
INSERT INTO dev.reservation (id, idClient, nbPassager, idLieu, dateArrivee) VALUES
    (1, 'Client1', 7,  2, '2026-03-19 09:00:00'),
    (2, 'Client2', 20, 3, '2026-03-19 08:00:00'),
    (3, 'Client3', 3,  2, '2026-03-19 09:10:00'),
    (4, 'Client4', 10, 2, '2026-03-19 09:15:00'),
    (5, 'Client5', 5,  2, '2026-03-19 09:20:00'),
    (6, 'Client6', 12, 2, '2026-03-19 13:30:00');

-- Reset des sequences
SELECT setval('dev.type_lieu_id_seq',  (SELECT MAX(id) FROM dev.type_lieu));
SELECT setval('dev.lieu_id_seq',       (SELECT MAX(id) FROM dev.lieu));
SELECT setval('dev.vehicule_id_seq',   (SELECT MAX(id) FROM dev.vehicule));
SELECT setval('dev.distance_id_seq',   (SELECT MAX(id) FROM dev.distance));
SELECT setval('dev.reservation_id_seq',(SELECT MAX(id) FROM dev.reservation));
SELECT setval('dev.parametre_id_seq',  (SELECT MAX(id) FROM dev.parametre));

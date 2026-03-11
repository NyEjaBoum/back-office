-- Script de peuplement des données SPRINT 5
-- Date: 2026-03-11
-- Reset et réinsertion des données de test

\c voiture_reservation_sprint5;
SET search_path TO dev;

-- =============================
-- 1. RESET DES TABLES
-- =============================

TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.type_lieu RESTART IDENTITY CASCADE;

-- =============================
-- 2. INSERTION DES DONNÉES
-- =============================

-- Types de lieux
INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Lieux
INSERT INTO dev.lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', 1),
    ('COLB', 'Colbert', 2),
    ('NOVO', 'Novotel', 2),
    ('IBIS', 'Ibis', 2);

-- Paramètres (tempsAttente = 30 min)
INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (40, 0);

-- Véhicules
INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('VOITURE', 4, 'H'),
    ('VAN-ES', 8, 'ES'),
    ('VAN-D1', 8, 'D'),
    ('VAN-D2', 8, 'D'),
    ('MINIBUS', 15, 'D');

-- Distances (une seule ligne par paire)
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 5.0),
    (1, 3, 6.0),
    (1, 4, 7.0),
    (2, 3, 2.0),
    (2, 4, 3.0),
    (3, 4, 1.5);


INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R1', 2, 2, '2026-03-10 08:00:00'),
    ('R2', 3, 3, '2026-03-10 08:15:00'),
    ('R3', 2, 4, '2026-03-10 08:25:00');

-- Réservations Groupe 2 : 09:00 (seul)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R4', 6, 2, '2026-03-10 09:00:00');

-- Réservations Groupe 3 : 10:00 (seul)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R5', 3, 3, '2026-03-10 10:00:00');

-- Réservations Groupe 4 : 11:00 (seul)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R6', 12, 4, '2026-03-10 11:00:00');

-- Réservations Groupe 5 : 12:00 (seul)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R7', 20, 2, '2026-03-10 12:00:00');

-- =============================
-- 3. VÉRIFICATIONS
-- =============================

SELECT '=== TYPE_LIEU ===' AS info;
SELECT * FROM dev.type_lieu ORDER BY id;

SELECT '=== LIEU ===' AS info;
SELECT l.id, l.code, l.libelle, t.code AS type_code
FROM dev.lieu l
LEFT JOIN dev.type_lieu t ON l.idTypeLieu = t.id
ORDER BY l.id;

SELECT '=== PARAMÈTRES ===' AS info;
SELECT * FROM dev.parametre;

SELECT '=== VÉHICULES ===' AS info;
SELECT id, reference, nbrPlace, typeCarburant FROM dev.vehicule ORDER BY nbrPlace;

SELECT '=== RÉSERVATIONS (2026-03-10) ===' AS info;
SELECT r.id, r.idClient, r.nbPassager, l.libelle AS lieu, r.dateArrivee 
FROM dev.reservation r 
JOIN dev.lieu l ON r.idLieu = l.id
ORDER BY r.dateArrivee, r.nbPassager DESC;

SELECT '=== DISTANCES ===' AS info;
SELECT d.id, l1.code AS from_code, l2.code AS to_code, d.km
FROM dev.distance d
JOIN dev.lieu l1 ON d."from" = l1.id
JOIN dev.lieu l2 ON d."to" = l2.id
ORDER BY d."from", d."to";
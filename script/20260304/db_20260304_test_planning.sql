-- Script de données de test simple pour la planification
-- Date: 2026-03-04
-- Objectif: Tester la fonctionnalité d'assignation avec des données simples

\c voiture_reservation;
SET search_path TO dev;

-- ===========================================
-- NETTOYAGE
-- ===========================================
TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.type_lieu RESTART IDENTITY CASCADE;

-- ===========================================
-- 1. TYPES DE LIEUX
-- ===========================================
INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- ===========================================
-- 2. LIEUX (avec idTypeLieu)
-- id: 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis
-- ===========================================
INSERT INTO dev.lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', 1),
    ('COLB', 'Colbert', 2),
    ('NOVO', 'Novotel', 2),
    ('IBIS', 'Ibis', 2);

-- ===========================================
-- 3. VÉHICULES
-- ===========================================
INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('VOITURE', 4, 'H'),
    ('VAN-ES', 8, 'ES'),
    ('VAN-D1', 8, 'D'),
    ('VAN-D2', 8, 'D'),
    ('MINIBUS', 15, 'D');

-- ===========================================
-- 4. PARAMÈTRES
-- tempsAttente=30 : réservations dans 30 min sont regroupées
-- ===========================================
INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (40, 30);

-- ===========================================
-- 5. DISTANCES (en km)
-- 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis
-- ===========================================
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 5.0),
    (1, 3, 6.0),
    (1, 4, 7.0),
    (2, 3, 2.0),
    (2, 4, 3.0),
    (3, 4, 1.5);

-- ===========================================
-- 6. RÉSERVATIONS DE TEST - Date: 2026-03-10
-- ===========================================
-- 
-- RÈGLE 1: Capacité >= somme passagers du groupe
-- RÈGLE 2: Trier par capacité croissante (plus petit véhicule)
-- RÈGLE 3: Égalité capacité → priorité Diesel
-- RÈGLE 4: Égalité Diesel → choix aléatoire
-- RÈGLE 5: Véhicule occupé → pas disponible
-- RÈGLE 6: Aucun véhicule → non assignée
--
-- ===========================================

-- VOL 08:00 - GROUPE 1 (dans 30 min)
-- R1(2 pass) + R2(3 pass) + R3(2 pass) = 7 passagers → VAN-D1 ou VAN-D2 (8 places, Diesel)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R1', 2, 2, '2026-03-10 08:00:00'),
    ('R2', 3, 3, '2026-03-10 08:15:00'),
    ('R3', 2, 4, '2026-03-10 08:25:00');

-- VOL 09:00 - GROUPE 2 (réservation seule)
-- R4(6 pass) = 6 passagers → VAN restant (8 places) car VAN-D1 ou D2 déjà pris
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R4', 6, 2, '2026-03-10 09:00:00');

-- VOL 10:00 - GROUPE 3 (réservation seule)
-- R5(3 pass) = 3 passagers → VOITURE (4 places) car plus petit >= 3
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R5', 3, 3, '2026-03-10 10:00:00');

-- VOL 11:00 - GROUPE 4 (réservation seule)
-- R6(12 pass) = 12 passagers → MINIBUS (15 places) car seul >= 12
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R6', 12, 4, '2026-03-10 11:00:00');

-- VOL 12:00 - GROUPE 5 (réservation seule)
-- R7(20 pass) = 20 passagers → NON ASSIGNÉE car aucun >= 20
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R7', 20, 2, '2026-03-10 12:00:00');

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT '=== VÉHICULES ===' AS info;
SELECT id, reference, nbrPlace, typeCarburant FROM dev.vehicule ORDER BY nbrPlace;

SELECT '=== RÉSERVATIONS (2026-03-10) ===' AS info;
SELECT r.id, r.idClient, r.nbPassager, l.libelle AS lieu, r.dateArrivee 
FROM dev.reservation r 
JOIN dev.lieu l ON r.idLieu = l.id
ORDER BY r.dateArrivee, r.nbPassager DESC;




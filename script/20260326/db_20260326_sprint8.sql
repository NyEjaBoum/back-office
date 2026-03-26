-- =====================================================
-- SCRIPT DE TEST SPRINT 8
-- Date: 2026-03-26
-- Objectif: Tester la gestion des véhicules retournés
--           et la priorité des réservations non assignées
-- =====================================================

\c voiture_reservation_sprint5;
SET search_path TO dev;

-- ===========================================
-- NETTOYAGE
-- ===========================================
TRUNCATE TABLE dev.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.type_lieu RESTART IDENTITY CASCADE;

TRUNCATE TABLE staging.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.type_lieu RESTART IDENTITY CASCADE;

TRUNCATE TABLE prod.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.type_lieu RESTART IDENTITY CASCADE;

-- ===========================================
-- CONFIGURATION DE BASE
-- ===========================================

-- Types de lieux
INSERT INTO type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Lieux
INSERT INTO lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport Ivato', (SELECT id FROM type_lieu WHERE code = 'AEROPORT')),
    -- ('COLBERT', 'Hotel Colbert', (SELECT id FROM type_lieu WHERE code = 'HOTEL')),
    -- ('CARLTON', 'Hotel Carlton', (SELECT id FROM type_lieu WHERE code = 'HOTEL')),
    ('PALISSANDRE', 'Hotel Palissandre', (SELECT id FROM type_lieu WHERE code = 'HOTEL'));

-- Paramètres : vitesse 60 km/h, temps d'attente 30 minutes
INSERT INTO parametre (vitesseMoyenne, tempsAttente) VALUES
    (50, 30);

INSERT INTO distance ("from", "to", km) VALUES
    -- Aeroport -> Hotels
    (1, 2, 50.0);  -- Aeroport -> Colbert
    -- (1, 3, 10.0),  -- Aeroport -> Carlton
    -- (1, 4, 15.0),  -- Aeroport -> Palissandre

    -- -- Hotels entre eux
    -- (2, 3, 3.0),   -- Colbert <-> Carlton
    -- (2, 4, 5.0),   -- Colbert <-> Palissandre
    -- (3, 4, 4.0);   -- Carlton <-> Palissandre

-- Véhicules avec capacités différentes
INSERT INTO vehicule (reference, nbrPlace, typeCarburant,heureDisponibilite) VALUES
    ('V20-DIESEL', 10, 'D','2026-03-26 10:00:00');      -- id=1, Grand véhicule
    -- ('V12-ESSENCE', 12, 'ES'),    -- id=2, Moyen véhicule
    -- ('V8-HYBRIDE', 8, 'H');       -- id=3, Petit véhicule

-- Réservations du groupe 08:00
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLIENT-001', 10, 2, '2026-03-26 08:00:00'),  -- R1: 15 pass -> Colbert
    ('CLIENT-002', 15, 2, '2026-03-26 10:10:00'),  -- R2: 10 pass -> Carlton
    ('CLIENT-003', 8, 2, '2026-03-26 10:15:00');   -- R3: 8 pass -> Palissandre

-- Nouvelles réservations à 08:30 (arrivent pendant le temps d'attente)
-- INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
--     ('CLIENT-004', 6, 2, '2026-03-26 08:30:00'),   -- R4: 6 pass -> Colbert
--     ('CLIENT-005', 12, 3, '2026-03-26 08:30:00'); -- R5: 12 pass -> Carlton
    -- ('CLIENT-006', 4, 3, '2026-03-26 09:00:00');  -- R5: 12 pass -> Carlton

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.type_lieu (code, libelle)
    SELECT code, libelle FROM type_lieu;

INSERT INTO staging.lieu (code, libelle, idTypeLieu)
    SELECT code, libelle, idTypeLieu FROM lieu;

INSERT INTO staging.vehicule (reference, nbrPlace, typeCarburant)
    SELECT reference, nbrPlace, typeCarburant FROM vehicule;

INSERT INTO staging.parametre (vitesseMoyenne, tempsAttente)
    SELECT vitesseMoyenne, tempsAttente FROM parametre;

INSERT INTO staging.distance ("from", "to", km)
    SELECT "from", "to", km FROM distance;

INSERT INTO staging.reservation (idClient, nbPassager, idLieu, dateArrivee)
    SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;

INSERT INTO prod.type_lieu (code, libelle)
    SELECT code, libelle FROM type_lieu;

INSERT INTO prod.lieu (code, libelle, idTypeLieu)
    SELECT code, libelle, idTypeLieu FROM lieu;

INSERT INTO prod.vehicule (reference, nbrPlace, typeCarburant)
    SELECT reference, nbrPlace, typeCarburant FROM vehicule;

INSERT INTO prod.parametre (vitesseMoyenne, tempsAttente)
    SELECT vitesseMoyenne, tempsAttente FROM parametre;

INSERT INTO prod.distance ("from", "to", km)
    SELECT "from", "to", km FROM distance;

INSERT INTO prod.reservation (idClient, nbPassager, idLieu, dateArrivee)
    SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;


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
TRUNCATE TABLE assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE type_lieu RESTART IDENTITY CASCADE;

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
    ('COLBERT', 'Hotel Colbert', (SELECT id FROM type_lieu WHERE code = 'HOTEL')),
    ('CARLTON', 'Hotel Carlton', (SELECT id FROM type_lieu WHERE code = 'HOTEL')),
    ('PALISSANDRE', 'Hotel Palissandre', (SELECT id FROM type_lieu WHERE code = 'HOTEL'));

-- Paramètres : vitesse 60 km/h, temps d'attente 30 minutes
INSERT INTO parametre (vitesseMoyenne, tempsAttente) VALUES
    (60, 30);

-- Distances (trajet d'environ 24 minutes aller-retour)
-- Aeroport <-> Hotels
INSERT INTO distance ("from", "to", km) VALUES
    -- Aeroport -> Hotels
    (1, 2, 12.0),  -- Aeroport -> Colbert
    (1, 3, 10.0),  -- Aeroport -> Carlton
    (1, 4, 15.0),  -- Aeroport -> Palissandre

    -- Hotels -> Aeroport
    (2, 1, 12.0),  -- Colbert -> Aeroport
    (3, 1, 10.0),  -- Carlton -> Aeroport
    (4, 1, 15.0),  -- Palissandre -> Aeroport

    -- Hotels entre eux
    (2, 3, 3.0),   -- Colbert -> Carlton
    (3, 2, 3.0),   -- Carlton -> Colbert
    (2, 4, 5.0),   -- Colbert -> Palissandre
    (4, 2, 5.0),   -- Palissandre -> Colbert
    (3, 4, 4.0),   -- Carlton -> Palissandre
    (4, 3, 4.0);   -- Palissandre -> Carlton

-- Véhicules avec capacités différentes
INSERT INTO vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('V20-DIESEL', 20, 'D'),      -- id=1, Grand véhicule
    ('V12-ESSENCE', 12, 'ES'),    -- id=2, Moyen véhicule
    ('V8-HYBRIDE', 8, 'H');       -- id=3, Petit véhicule

-- ===========================================
-- SCÉNARIO DE TEST SPRINT 8
-- ===========================================

/*
SCÉNARIO:
---------
Groupe 08:00 - Premier passage
  - R1: 15 passagers -> Colbert (08:00)
  - R2: 10 passagers -> Carlton (08:00)
  - R3: 8 passagers -> Palissandre (08:00)

  TOTAL: 33 passagers
  CAPACITÉ TOTALE: 20 + 12 + 8 = 40 places

  RÉSULTAT ATTENDU (sans Sprint 8):
    - V20 prend R1 (15 pass), reste 5 places
    - V20 prend 5 de R2, reste 5 de R2 NON ASSIGNÉS (décalés)
    - V12 prend les 8 de R3

  TRAJET V20: Aeroport -> Colbert -> Carlton -> Aeroport
    Distance: 12 + 3 + 10 = 25 km
    Durée: 25 / 60 = 0.42h = 25 minutes
    Retour: 08:25

  TRAJET V12: Aeroport -> Palissandre -> Aeroport
    Distance: 15 + 15 = 30 km
    Durée: 30 / 60 = 0.5h = 30 minutes
    Retour: 08:30

SPRINT 8 - Quand V20 revient à 08:25:
  - 5 passagers de R2 sont en attente (DÉCALÉS)
  - Nouveau temps d'attente: 08:25 -> 08:55 (30 min)

Nouvelles réservations à 08:30:
  - R4: 6 passagers -> Colbert (08:30)
  - R5: 12 passagers -> Carlton (08:30)

SPRINT 8 - RÉSULTAT ATTENDU:
  1. PRIORITÉ aux 5 passagers décalés de R2
  2. V20 (20 places) prend:
     - 5 décalés de R2 (PRIORITAIRES)
     - 6 de R4
     - 9 de R5
     Reste: 3 de R5 non assignés

  3. Quand V12 revient à 08:30:
     - Nouveau temps d'attente: 08:30 -> 09:00
     - V12 (12 places) prend les 3 restants de R5
*/

-- Réservations du groupe 08:00
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLIENT-001', 15, 2, '2026-03-26 08:00:00'),  -- R1: 15 pass -> Colbert
    ('CLIENT-002', 10, 3, '2026-03-26 08:00:00'),  -- R2: 10 pass -> Carlton
    ('CLIENT-003', 8, 4, '2026-03-26 08:00:00');   -- R3: 8 pass -> Palissandre

-- Nouvelles réservations à 08:30 (arrivent pendant le temps d'attente)
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLIENT-004', 6, 2, '2026-03-26 08:30:00'),   -- R4: 6 pass -> Colbert
    ('CLIENT-005', 12, 3, '2026-03-26 08:30:00');  -- R5: 12 pass -> Carlton

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

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT '===============================================' AS separateur;
SELECT 'DONNÉES CHARGÉES POUR TEST SPRINT 8' AS titre;
SELECT '===============================================' AS separateur;

SELECT 'LIEUX' AS table_name, COUNT(*) AS count FROM lieu;
SELECT 'VEHICULES' AS table_name, COUNT(*) AS count FROM vehicule;
SELECT 'PARAMÈTRES' AS table_name, COUNT(*) AS count FROM parametre;
SELECT 'DISTANCES' AS table_name, COUNT(*) AS count FROM distance;
SELECT 'RESERVATIONS' AS table_name, COUNT(*) AS count FROM reservation;

SELECT '===============================================' AS separateur;
SELECT 'DÉTAILS DES RÉSERVATIONS' AS titre;
SELECT '===============================================' AS separateur;

SELECT
    id,
    idClient,
    nbPassager,
    (SELECT libelle FROM lieu WHERE id = idLieu) AS hotel,
    dateArrivee,
    TO_CHAR(dateArrivee, 'HH24:MI') AS heure
FROM reservation
ORDER BY dateArrivee, nbPassager DESC;

SELECT '===============================================' AS separateur;
SELECT 'VÉHICULES DISPONIBLES' AS titre;
SELECT '===============================================' AS separateur;

SELECT
    id,
    reference,
    nbrPlace,
    typeCarburant
FROM vehicule
ORDER BY nbrPlace DESC;

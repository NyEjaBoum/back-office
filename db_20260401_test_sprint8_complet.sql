-- =====================================================
-- SCRIPT DE TEST SPRINT 8 COMPLET
-- Date: 2026-04-01
-- Objectif: Tester la règle de gestion Sprint 8:
--   1. Retour véhicule déclenche nouveau regroupement
--   2. Réservations non assignées deviennent prioritaires
--   3. Nouveau temps d'attente redémarre
--   4. Véhicule part même s'il n'est pas plein
-- =====================================================

\c voiture_reservation_sprint5;
SET search_path TO dev;

-- ===========================================
-- NETTOYAGE COMPLET
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
-- SCENARIO 1: RETOUR VEHICULE AVEC PRIORITE DECALEE
-- ===========================================
-- Configuration:
--   - 1 véhicule (10 places), disponible à 08:00
--   - Temps d'attente: 30 min
--   - Vitesse: 60 km/h
--   - Distance aéroport -> hôtels: 30 km (donc 30 min aller-retour = 1h total)
--
-- Réservations:
--   - R1: 10 pass, arrivée 08:00 -> Véhicule plein, départ 08:30, retour 09:30
--   - R2: 5 pass, arrivée 08:15 -> Non assignée (véhicule occupé)
--   - R3: 3 pass, arrivée 09:00 -> Non assignée (véhicule occupé)
--   - R4: 4 pass, arrivée 09:35 -> Arrive après retour véhicule
--
-- Résultat attendu:
--   1er trajet: R1 (10 pass), départ 08:30, retour ~09:30
--   2e trajet: R2 (décalée, priorité), R3 (décalée, priorité), R4
--              Nouveau regroupement à 09:30, attente jusqu'à 10:00
--              Véhicule part même si pas plein (5+3+4=12, mais seulement 10 places)
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

-- Paramètres: vitesse 60 km/h, temps d'attente 30 minutes
INSERT INTO parametre (vitesseMoyenne, tempsAttente) VALUES
    (50, 30);

-- Distances (30 km = 30 min de trajet à 60 km/h)
INSERT INTO distance ("from", "to", km) VALUES
    (1, 2, 30.0),   -- Aeroport -> Colbert
    (1, 3, 35.0),   -- Aeroport -> Carlton
    (1, 4, 40.0),   -- Aeroport -> Palissandre
    (2, 3, 5.0),    -- Colbert <-> Carlton
    (2, 4, 10.0),   -- Colbert <-> Palissandre
    (3, 4, 8.0);    -- Carlton <-> Palissandre

-- 1 véhicule disponible à 08:00
INSERT INTO vehicule (reference, nbrPlace, typeCarburant, heureDisponibilite) VALUES
    ('VAN-DIESEL-01', 10, 'D', '2026-04-01 08:00:00');

-- Réservations Scénario 1
-- Groupe initial 08:00-08:30
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLI-001', 10, 2, '2026-04-01 08:00:00'),  -- R1: 10 pass -> Colbert (remplit le véhicule)
    ('CLI-002', 5, 3, '2026-04-01 08:15:00'),   -- R2: 5 pass -> Carlton (sera décalée)
    ('CLI-003', 3, 4, '2026-04-01 09:00:00'),   -- R3: 3 pass -> Palissandre (sera décalée)
    ('CLI-004', 4, 2, '2026-04-01 09:35:00');   -- R4: 4 pass -> Colbert (dans la fenêtre 09:00-09:30)

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.type_lieu (code, libelle)
    SELECT code, libelle FROM type_lieu;

INSERT INTO staging.lieu (code, libelle, idTypeLieu)
    SELECT code, libelle, idTypeLieu FROM lieu;

INSERT INTO staging.vehicule (reference, nbrPlace, typeCarburant, heureDisponibilite)
    SELECT reference, nbrPlace, typeCarburant, heureDisponibilite FROM vehicule;

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

INSERT INTO prod.vehicule (reference, nbrPlace, typeCarburant, heureDisponibilite)
    SELECT reference, nbrPlace, typeCarburant, heureDisponibilite FROM vehicule;

INSERT INTO prod.parametre (vitesseMoyenne, tempsAttente)
    SELECT vitesseMoyenne, tempsAttente FROM parametre;

INSERT INTO prod.distance ("from", "to", km)
    SELECT "from", "to", km FROM distance;

INSERT INTO prod.reservation (idClient, nbPassager, idLieu, dateArrivee)
    SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;

-- ===========================================
-- RESULTAT ATTENDU SCENARIO 1
-- ===========================================
--
-- TRAJET 1 (Groupe 08:00):
--   - Véhicule: VAN-DIESEL-01
--   - Réservations: R1 (10 pass) -> véhicule plein immédiatement
--   - Heure départ: 08:00 (plein dès l'arrivée de R1)
--   - Distance: 60 km (Aeroport -> Colbert -> Aeroport)
--   - Heure retour: 09:00
--
-- R2 (5 pass) ne peut pas être assignée -> DECALEE
--
-- NOUVEAU REGROUPEMENT à 09:00 (retour véhicule):
--   - Fenêtre: 09:00 -> 09:30
--   - Réservations prioritaires (décalées): R2 (5 pass, priorité backlog)
--   - Réservations fraîches dans la fenêtre: R3 (3 pass, 09:00), R4 (4 pass, 09:30)
--   - Total disponible: 12 passagers, capacité 10
--   - Remplissage: R2 (cible, 5p) + R4 (best-fit pour 5 places, |4-5|=1) + R3 (1p, complète)
--
-- TRAJET 2 (Groupe 09:00):
--   - Véhicule: VAN-DIESEL-01
--   - Réservations: R2(5) + R4(4) + R3(1) = 10 (plein)
--   - Heure départ: 09:30 (arrivée de R4, dernier passager chargé)
--   - Distance: 83 km (Aeroport -> Colbert -> Carlton -> Palissandre -> Aeroport)
--   - Heure retour: 10:53
--
-- TRAJET 3 (Groupe 10:53):
--   - Véhicule: VAN-DIESEL-01
--   - Réservations: R3 restant (2 pass, décalée)
--   - Heure départ: 10:53
--
-- ===========================================

SELECT 'Données de test Sprint 8 Scénario 1 insérées avec succès' AS status;
SELECT 'Date à tester: 2026-04-01' AS info;
SELECT 'Vérifications:' AS check_title;
SELECT '1. R1 assignée en premier (10 pass)' AS check1;
SELECT '2. R2 et R3 marquées DECALEES' AS check2;
SELECT '3. Nouveau regroupement déclenché au retour (09:30)' AS check3;
SELECT '4. R2 prioritaire (backlog), R4 en best-fit, R3 complète' AS check4;
SELECT '5. Trajet 2: R2(5)+R4(4)+R3(1)=10, départ 09:30, retour 10:53' AS check5;
SELECT '6. Trajet 3: R3(2 restants), départ 10:53' AS check6;

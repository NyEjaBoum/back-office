-- =====================================================
-- TEST SPRINT 8 - SCENARIO SIMPLIFIE
-- Date: 2026-03-26
-- Objectif: Scénario minimal pour tester rapidement
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
-- CONFIGURATION MINIMALE
-- ===========================================

-- Types de lieux
INSERT INTO type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Lieux
INSERT INTO lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', (SELECT id FROM type_lieu WHERE code = 'AEROPORT')),
    ('HOTEL1', 'Hotel Central', (SELECT id FROM type_lieu WHERE code = 'HOTEL'));

-- Paramètres : vitesse 60 km/h, temps d'attente 20 minutes
INSERT INTO parametre (vitesseMoyenne, tempsAttente) VALUES
    (60, 20);

-- Distances (trajet de 20 minutes aller-retour)
INSERT INTO distance ("from", "to", km) VALUES
    (1, 2, 10.0),  -- Aeroport -> Hotel : 10 km
    (2, 1, 10.0);  -- Hotel -> Aeroport : 10 km

-- 1 seul véhicule de 10 places
INSERT INTO vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('V10', 10, 'D');

-- ===========================================
-- SCENARIO SIMPLE
-- ===========================================

/*
SCENARIO:
---------
08:00 - Premier groupe:
  - R1: 8 passagers
  - R2: 5 passagers
  TOTAL: 13 passagers pour 10 places

RESULTAT ATTENDU:
  - V10 prend R1 (8 passagers) complètement
  - V10 prend 2 de R2
  - RESTE: 3 de R2 → DÉCALÉS

TRAJET V10: Aeroport -> Hotel -> Aeroport
  Distance: 10 + 10 = 20 km
  Durée: 20 / 60 = 0.33h = 20 minutes
  Retour: 08:20

SPRINT 8 - Quand V10 revient à 08:20:
  - 3 passagers de R2 en attente (DÉCALÉS)
  - Nouveau temps d'attente: 08:20 -> 08:40 (20 min)

08:25 - Nouvelle réservation:
  - R3: 7 passagers

SPRINT 8 - RÉSULTAT ATTENDU:
  1. V10 (10 places) prend:
     - 3 décalés de R2 (PRIORITAIRES)
     - 7 de R3
     TOTAL: 10 passagers (véhicule plein)

VALIDATION:
  ✓ Les 3 décalés sont assignés en priorité
  ✓ V10 fait 2 trajets
  ✓ Tous les passagers sont assignés
*/

-- Réservations à 08:00
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('C001', 8, 2, '2026-03-26 08:00:00'),   -- R1: 8 passagers
    ('C002', 5, 2, '2026-03-26 08:00:00');   -- R2: 5 passagers (3 seront décalés)

-- Nouvelle réservation à 08:25
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('C003', 7, 2, '2026-03-26 08:25:00');   -- R3: 7 passagers

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.type_lieu (code, libelle) SELECT code, libelle FROM type_lieu;
INSERT INTO staging.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM lieu;
INSERT INTO staging.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM vehicule;
INSERT INTO staging.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM parametre;
INSERT INTO staging.distance ("from", "to", km) SELECT "from", "to", km FROM distance;
INSERT INTO staging.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;

INSERT INTO prod.type_lieu (code, libelle) SELECT code, libelle FROM type_lieu;
INSERT INTO prod.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM lieu;
INSERT INTO prod.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM vehicule;
INSERT INTO prod.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM parametre;
INSERT INTO prod.distance ("from", "to", km) SELECT "from", "to", km FROM distance;
INSERT INTO prod.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT '===============================================' AS separateur;
SELECT 'SCENARIO SIMPLIFIE - DONNEES CHARGEES' AS titre;
SELECT '===============================================' AS separateur;

SELECT
    r.id,
    r.idClient,
    r.nbPassager,
    TO_CHAR(r.dateArrivee, 'HH24:MI') AS heure
FROM reservation r
ORDER BY r.dateArrivee, r.nbPassager DESC;

SELECT '===============================================' AS separateur;
SELECT 'RESULTAT ATTENDU:' AS titre;
SELECT '===============================================' AS separateur;
SELECT '1. V10 prend 8 + 2 = 10 passagers à 08:00' AS etape;
SELECT '2. 3 passagers de C002 sont DECALES' AS etape;
SELECT '3. V10 revient à 08:20, attend jusqu''à 08:25' AS etape;
SELECT '4. V10 prend 3 décalés (PRIORITE) + 7 de C003 = 10 passagers à 08:25' AS etape;
SELECT '5. Tous les passagers sont assignés' AS etape;

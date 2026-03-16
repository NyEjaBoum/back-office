-- Script de réinitialisation complète des données
-- Date: 2026-03-03
-- Description: Nettoyer TOUTES les tables de données (tous schémas),
--              réinitialiser les séquences à 1, puis insérer les données de test.
-- Usage: exécuter en tant que postgres après db_20260303_init.sql (structure)

\c voiture_reservation;

-- ===========================================
-- NETTOYAGE COMPLET (enfants d'abord, parents ensuite)
-- ===========================================

-- DEV
TRUNCATE TABLE dev.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.type_lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.token RESTART IDENTITY CASCADE;

-- STAGING
TRUNCATE TABLE staging.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.type_lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.token RESTART IDENTITY CASCADE;

-- PROD
TRUNCATE TABLE prod.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.type_lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.token RESTART IDENTITY CASCADE;

-- ===========================================
-- INSERTION DES DONNÉES DE TEST
-- ===========================================

-- Types de lieux
INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Lieux (1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton)
INSERT INTO dev.lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', (SELECT id FROM dev.type_lieu WHERE code = 'AEROPORT')),
    ('COLB', 'Hotel 1', (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL'));
    -- ('NOVO', 'Novotel', (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL')),
    -- ('IBIS', 'Ibis', (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL')),
    -- ('LOKA', 'Lokanga', (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL')),
    -- ('CARL', 'Carlton', (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL'));

-- Véhicules
INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('Vehicule 1', 12, 'D'),
    ('Vehicule 2', 5, 'ES'),
    ('Vehicule 3', 5, 'D'),
    ('Vehicule 4', 12, 'ES');
    
-- Paramètres (vitesse moyenne = 40 km/h, temps d'attente = 30 min)
INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (50, 0);

-- Distances (en km, une seule ligne par paire)
-- 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 50.0);

-- Réservations de test
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLIENT1', 7, 2, '2026-03-12 09:00:00'),
    ('CLIENT2', 11, 2, '2026-03-12 09:00:00'),
    ('CLIENT3', 3, 2, '2026-03-12 09:00:00'),
    ('CLIENT4', 1, 2, '2026-03-12 09:00:00'),
    ('CLIENT5', 2, 2, '2026-03-12 09:00:00'),
    ('CLIENT6', 20, 2, '2026-03-12 09:00:00');

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.type_lieu (code, libelle) SELECT code, libelle FROM dev.type_lieu;
INSERT INTO prod.type_lieu (code, libelle) SELECT code, libelle FROM dev.type_lieu;

INSERT INTO staging.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM dev.lieu;
INSERT INTO prod.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM dev.lieu;

INSERT INTO staging.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM dev.vehicule;
INSERT INTO prod.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM dev.vehicule;

INSERT INTO staging.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM dev.parametre;
INSERT INTO prod.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM dev.parametre;

INSERT INTO staging.distance ("from", "to", km) SELECT "from", "to", km FROM dev.distance;
INSERT INTO prod.distance ("from", "to", km) SELECT "from", "to", km FROM dev.distance;

INSERT INTO staging.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM dev.reservation;
INSERT INTO prod.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM dev.reservation;

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT 'LIEUX' AS table_name, count(*) FROM dev.lieu;
SELECT 'VEHICULES' AS table_name, count(*) FROM dev.vehicule;
SELECT 'PARAMETRES' AS table_name, count(*) FROM dev.parametre;
SELECT 'DISTANCES' AS table_name, count(*) FROM dev.distance;
SELECT 'RESERVATIONS' AS table_name, count(*) FROM dev.reservation;

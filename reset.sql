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
TRUNCATE TABLE dev.token RESTART IDENTITY CASCADE;

-- STAGING
TRUNCATE TABLE staging.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.token RESTART IDENTITY CASCADE;

-- PROD
TRUNCATE TABLE prod.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.token RESTART IDENTITY CASCADE;

-- ===========================================
-- INSERTION DES DONNÉES DE TEST
-- ===========================================

-- Lieux (1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton)
INSERT INTO dev.lieu (code, libelle) VALUES
    ('AERO', 'Aeroport'),
    ('COLB', 'Colbert'),
    ('NOVO', 'Novotel'),
    ('IBIS', 'Ibis'),
    ('LOKA', 'Lokanga'),
    ('CARL', 'Carlton');

-- Véhicules
INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('MINIBUS-1', 15, 'D'),
    ('VAN-1', 8, 'ES'),
    ('VAN-2', 8, 'D'),
    ('VOITURE-1', 4, 'H'),
    ('BUS-1', 30, 'D');

-- Paramètres (vitesse moyenne = 40 km/h, temps d'attente = 30 min)
INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (40, 30);

-- Distances (en km, une seule ligne par paire)
-- 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 7.0),
    (1, 3, 5.0),
    (1, 4, 6.0),
    (1, 5, 10.0),
    (1, 6, 8.0),
    (2, 3, 3.5),
    (2, 4, 2.2),
    (2, 5, 5.0),
    (2, 6, 4.1),
    (3, 4, 1.8),
    (3, 5, 3.7),
    (3, 6, 2.9),
    (4, 5, 4.5),
    (4, 6, 2.0),
    (5, 6, 3.3);

-- Réservations de test
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('1001', 3, 2, '2026-03-01 08:00:00'),
    ('1002', 2, 3, '2026-03-01 08:30:00'),
    ('1003', 4, 4, '2026-03-01 08:15:00'),
    ('1004', 7, 5, '2026-03-01 08:08:00'),
    ('1005', 8, 6, '2026-03-01 09:00:00'),
    ('1006', 1, 2, '2026-03-01 08:02:00'),
    ('1007', 12, 3, '2026-03-01 09:00:00'),
    ('1008', 5, 4, '2026-03-01 09:00:00'),
    ('1009', 2, 5, '2026-03-01 09:00:00'),
    ('1010', 15, 6, '2026-03-01 09:00:00');

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.lieu (code, libelle) SELECT code, libelle FROM dev.lieu;
INSERT INTO prod.lieu (code, libelle) SELECT code, libelle FROM dev.lieu;

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

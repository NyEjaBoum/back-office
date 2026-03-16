-- Script de réinitialisation complète des données (version simplifiée Sprint 6)
-- Date: 2026-03-16

\c voiture_reservation_sprint5;

SET search_path TO dev;

-- ===========================================
-- NETTOYAGE COMPLET (enfants d'abord, parents ensuite)
-- ===========================================

TRUNCATE TABLE assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE type_lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE token RESTART IDENTITY CASCADE;

-- ===========================================
-- INSERTION DES DONNÉES DE TEST (DEV)
-- ===========================================

-- Types de lieux
INSERT INTO type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Lieux (1=Aeroport, 2=Colbert)
INSERT INTO lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', (SELECT id FROM type_lieu WHERE code = 'AEROPORT')),
    ('COLB', 'Hotel 1', (SELECT id FROM type_lieu WHERE code = 'HOTEL'));
    -- Tu peux décommenter et compléter ici si tu veux plus de lieux

-- Véhicules
INSERT INTO vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('Vehicule 1', 12, 'D'),
    ('Vehicule 2', 5, 'ES'),
    ('Vehicule 3', 5, 'D'),
    ('Vehicule 4', 12, 'ES');

-- Paramètres
INSERT INTO parametre (vitesseMoyenne, tempsAttente) VALUES
    (50, 0);

-- Distances
INSERT INTO distance ("from", "to", km) VALUES
    (1, 2, 50.0);

-- Réservations de test
INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('CLIENT1', 7, 2, '2026-03-12 09:00:00'),
    ('CLIENT2', 11, 2, '2026-03-12 09:00:00'),
    ('CLIENT3', 3, 2, '2026-03-12 09:00:00'),
    ('CLIENT4', 1, 2, '2026-03-12 09:00:00'),
    ('CLIENT5', 2, 2, '2026-03-12 09:00:00'),
    ('CLIENT6', 20, 2, '2026-03-12 09:00:00');

-- ===========================================
-- COPIER VERS STAGING ET PROD
-- ===========================================
INSERT INTO staging.type_lieu (code, libelle) SELECT code, libelle FROM type_lieu;
INSERT INTO prod.type_lieu (code, libelle) SELECT code, libelle FROM type_lieu;

INSERT INTO staging.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM lieu;
INSERT INTO prod.lieu (code, libelle, idTypeLieu) SELECT code, libelle, idTypeLieu FROM lieu;

INSERT INTO staging.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM vehicule;
INSERT INTO prod.vehicule (reference, nbrPlace, typeCarburant) SELECT reference, nbrPlace, typeCarburant FROM vehicule;

INSERT INTO staging.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM parametre;
INSERT INTO prod.parametre (vitesseMoyenne, tempsAttente) SELECT vitesseMoyenne, tempsAttente FROM parametre;

INSERT INTO staging.distance ("from", "to", km) SELECT "from", "to", km FROM distance;
INSERT INTO prod.distance ("from", "to", km) SELECT "from", "to", km FROM distance;

INSERT INTO staging.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;
INSERT INTO prod.reservation (idClient, nbPassager, idLieu, dateArrivee) SELECT idClient, nbPassager, idLieu, dateArrivee FROM reservation;

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT 'LIEUX' AS table_name, count(*) FROM lieu;
SELECT 'VEHICULES' AS table_name, count(*) FROM vehicule;
SELECT 'PARAMETRES' AS table_name, count(*) FROM parametre;
SELECT 'DISTANCES' AS table_name, count(*) FROM distance;
SELECT 'RESERVATIONS' AS table_name, count(*) FROM reservation;
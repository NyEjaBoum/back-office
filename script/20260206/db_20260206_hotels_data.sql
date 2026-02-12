-- Script d'insertion des hôtels de test
-- Date: 2026-02-06
-- Description: Ajouter des données de test pour les hôtels et réservations

-- Se connecter à la base de données
\c voiture_reservation;

-- Réinitialisation des tables hôtels (et réservations si besoin)
TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.reservation RESTART IDENTITY CASCADE;

TRUNCATE TABLE dev.hotel RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.hotel RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.hotel RESTART IDENTITY CASCADE;

-- Insérer des hôtels dans le schéma dev
INSERT INTO dev.hotel (nom) VALUES 
    ('Colbert'),
    ('Novotel'),
    ('Ibis'),
    ('Lokanga');

-- Copier les données vers staging et prod
INSERT INTO staging.hotel (nom) SELECT nom FROM dev.hotel;
INSERT INTO prod.hotel (nom) SELECT nom FROM dev.hotel;

-- Insérer des réservations de test dans le schéma dev
INSERT INTO dev.reservation (idClient, nbPassager, idHotel, dateArrivee) VALUES
    ('4631', 11, 3, '2026-02-05 00:01:00'),
    ('4394', 1, 3, '2026-02-05 23:55:00'),
    ('8054', 2, 1, '2026-02-09 10:17:00'),
    ('1432', 4, 2, '2026-02-01 15:25:00'),
    ('7861', 4, 1, '2026-01-28 07:11:00'),
    ('3308', 5, 1, '2026-01-28 07:45:00'),
    ('4484', 13, 2, '2026-02-28 08:25:00'),
    ('9687', 8, 2, '2026-02-28 13:00:00'),
    ('6302', 7, 1, '2026-02-15 13:00:00'),
    ('8640', 1, 4, '2026-02-18 22:55:00');

-- Copier les réservations vers staging et prod
INSERT INTO staging.reservation (idClient, nbPassager, idHotel, dateArrivee)
    SELECT idClient, nbPassager, idHotel, dateArrivee FROM dev.reservation;
INSERT INTO prod.reservation (idClient, nbPassager, idHotel, dateArrivee)
    SELECT idClient, nbPassager, idHotel, dateArrivee FROM dev.reservation;

-- Vérification
SELECT * FROM dev.hotel;
SELECT * FROM dev.reservation;
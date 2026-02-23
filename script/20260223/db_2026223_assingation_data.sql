-- Script d'insertion de données de test pour la planification/assignation
-- Date: 2026-02-23

\c voiture_reservation;

-- Nettoyage des tables principales
TRUNCATE TABLE dev.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;

-- 1. Insérer des lieux (id 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton)
INSERT INTO dev.lieu (code, libelle) VALUES
    ('AERO', 'Aeroport'),
    ('COLB', 'Colbert'),
    ('NOVO', 'Novotel'),
    ('IBIS', 'Ibis'),
    ('LOKA', 'Lokanga'),
    ('CARL', 'Carlton');

-- 2. Insérer des véhicules (capacités variées, différents carburants)
INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('MINIBUS-1', 15, 'D'),
    ('VAN-1', 8, 'ES'),
    ('VAN-2', 8, 'D'),
    ('VOITURE-1', 4, 'H'),
    ('BUS-1', 30, 'D');

-- 3. Insérer des paramètres (temps d'attente toléré = 30 min, vitesse moyenne = 40 km/h)
INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (40, 30);

-- 4. Insérer des distances (en km, une seule ligne par paire)
-- id des lieux: 1=Aeroport, 2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton
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

-- 5. Insérer des réservations (dates proches pour tester le regroupement)
-- Les idLieu pointent vers les hotels (2=Colbert, 3=Novotel, 4=Ibis, 5=Lokanga, 6=Carlton)
INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('1001', 3, 2, '2026-03-01 08:00:00'),
    ('1002', 2, 3, '2026-03-01 08:10:00'),
    ('1003', 4, 4, '2026-03-01 08:25:00'),
    ('1004', 7, 5, '2026-03-01 09:00:00'),
    ('1005', 8, 6, '2026-03-01 09:05:00'),
    ('1006', 1, 2, '2026-03-01 09:20:00'),
    ('1007', 12, 3, '2026-03-01 10:00:00'),
    ('1008', 5, 4, '2026-03-01 10:10:00'),
    ('1009', 2, 5, '2026-03-01 10:15:00'),
    ('1010', 15, 6, '2026-03-01 11:00:00');

-- 6. (Optionnel) Exemple d'assignation (à supprimer si tu veux tester l'algo)
-- INSERT INTO dev.assignation (idVehicule, idReservation, datePlanification) VALUES
--     (1, 1, NOW()),
--     (1, 2, NOW()),
--     (2, 3, NOW());

-- Copier les données vers staging et prod
TRUNCATE TABLE staging.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE staging.distance RESTART IDENTITY CASCADE;

TRUNCATE TABLE prod.assignation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE prod.distance RESTART IDENTITY CASCADE;

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

-- Pas d'assignation copiée (doit être générée par l'algo)
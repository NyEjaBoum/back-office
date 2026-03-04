\c voiture_reservation;
SET search_path TO dev;

TRUNCATE TABLE dev.reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.parametre RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE dev.type_lieu RESTART IDENTITY CASCADE;

INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

INSERT INTO dev.lieu (code, libelle, idTypeLieu) VALUES
    ('AERO', 'Aeroport', 1),
    ('COLB', 'Colbert', 2),
    ('NOVO', 'Novotel', 2),
    ('IBIS', 'Ibis', 2);

INSERT INTO dev.vehicule (reference, nbrPlace, typeCarburant) VALUES
    ('VOITURE', 4, 'H'),
    ('VAN-ES', 8, 'ES'),
    ('VAN-D1', 8, 'D'),
    ('VAN-D2', 8, 'D'),
    ('MINIBUS', 15, 'D');

INSERT INTO dev.parametre (vitesseMoyenne, tempsAttente) VALUES
    (40, 30);

INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 5.0),
    (1, 3, 6.0),
    (1, 4, 7.0),
    (2, 3, 2.0),
    (2, 4, 3.0),
    (3, 4, 1.5);

INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R1', 2, 2, '2026-03-10 08:00:00'),
    ('R2', 3, 3, '2026-03-10 08:15:00'),
    ('R3', 2, 4, '2026-03-10 08:25:00');

INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R4', 6, 2, '2026-03-10 09:00:00');

INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R5', 3, 3, '2026-03-10 10:00:00');

INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R6', 12, 4, '2026-03-10 11:00:00');

INSERT INTO dev.reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES
    ('R7', 20, 2, '2026-03-10 12:00:00');

SELECT '=== VÉHICULES ===' AS info;
SELECT id, reference, nbrPlace, typeCarburant FROM dev.vehicule ORDER BY nbrPlace;

SELECT '=== RÉSERVATIONS (2026-03-10) ===' AS info;
SELECT r.id, r.idClient, r.nbPassager, l.libelle AS lieu, r.dateArrivee 
FROM dev.reservation r 
JOIN dev.lieu l ON r.idLieu = l.id
ORDER BY r.dateArrivee, r.nbPassager DESC;
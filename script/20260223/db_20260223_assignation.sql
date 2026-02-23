-- Script création table assignation
-- Date: 2026-02-23

psql -U app_dev -d voiture_reservation;

CREATE TABLE assignation (
    id SERIAL PRIMARY KEY,
    idVehicule INTEGER NOT NULL REFERENCES vehicule(id),
    idReservation INTEGER NOT NULL REFERENCES reservation(id),
    datePlanification TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE staging.assignation (LIKE dev.assignation INCLUDING ALL);
CREATE TABLE prod.assignation (LIKE dev.assignation INCLUDING ALL);
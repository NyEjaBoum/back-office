-- Script création table assignation
-- Date: 2026-02-23

\c voiture_reservation;
SET search_path TO dev;

CREATE TABLE assignation (
    id SERIAL PRIMARY KEY,
    idVehicule INTEGER NOT NULL REFERENCES vehicule(id),
    idReservation INTEGER NOT NULL REFERENCES reservation(id),
    datePlanification TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE staging.assignation (LIKE dev.assignation INCLUDING ALL);
CREATE TABLE prod.assignation (LIKE dev.assignation INCLUDING ALL);
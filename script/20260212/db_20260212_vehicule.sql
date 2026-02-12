
-- Script création table vehicule
-- Date: 2026-02-12

\c voiture_reservation;

CREATE TABLE IF NOT EXISTS dev.vehicule (
	id SERIAL PRIMARY KEY,
	reference VARCHAR(100) NOT NULL,
	nbrPlace INTEGER NOT NULL,
	typeCarburant VARCHAR(2) NOT NULL,
	CONSTRAINT vehicule_nbrPlace_check CHECK (nbrPlace > 0),
	CONSTRAINT vehicule_typeCarburant_check CHECK (typeCarburant IN ('D', 'ES', 'H'))
);

CREATE UNIQUE INDEX IF NOT EXISTS vehicule_reference_uq ON dev.vehicule(reference);

CREATE TABLE IF NOT EXISTS staging.vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE IF NOT EXISTS prod.vehicule (LIKE dev.vehicule INCLUDING ALL);


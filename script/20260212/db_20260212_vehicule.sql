
-- Script création table vehicule
-- Date: 2026-02-12

psql -U app_dev -d voiture_reservation;

CREATE TABLE vehicule (
	id SERIAL PRIMARY KEY,
	reference VARCHAR(100) NOT NULL,
	nbrPlace INTEGER NOT NULL,
	typeCarburant VARCHAR(2) NOT NULL,
	CONSTRAINT vehicule_nbrPlace_check CHECK (nbrPlace > 0),
	CONSTRAINT vehicule_typeCarburant_check CHECK (typeCarburant IN ('D', 'ES', 'H'))
);

CREATE TABLE token (
	id SERIAL PRIMARY KEY,
	token VARCHAR(255) NOT NULL,
	date_expiration TIMESTAMP NOT NULL
);

CREATE TABLE staging.vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE prod.vehicule (LIKE dev.vehicule INCLUDING ALL);

CREATE TABLE staging.token (LIKE dev.token INCLUDING ALL);
CREATE TABLE prod.token (LIKE dev.token INCLUDING ALL);


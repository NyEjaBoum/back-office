-- Script d'initialisation complet (propre)
-- Date: 2026-02-18
-- Objectif:
--  - Drop & recreate la base
--  - Recréer schemas/roles/grants (comme db_20260202_init.sql)
--  - Créer toutes les tables en remplaçant `hotel` par `lieu`
--  - Ajouter les nouvelles tables: lieu, parametre, distance
--  - Règle métier distance: une seule ligne par paire (aller = retour)

-- 1) Drop & recreate la base
\c postgres;
DROP DATABASE IF EXISTS voiture_reservation;
CREATE DATABASE voiture_reservation;

\c voiture_reservation;

-- 2) Schémas
CREATE SCHEMA dev;
CREATE SCHEMA staging;
CREATE SCHEMA prod;

-- 3) Rôles (si absents)
DO $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_dev') THEN
		CREATE ROLE app_dev LOGIN PASSWORD 'dev_pwd';
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_staging') THEN
		CREATE ROLE app_staging LOGIN PASSWORD 'staging_pwd';
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_prod') THEN
		CREATE ROLE app_prod LOGIN PASSWORD 'prod_pwd';
	END IF;
END $$;

-- 4) Droits
-- DEV
GRANT USAGE, CREATE ON SCHEMA dev TO app_dev;
GRANT USAGE, CREATE ON SCHEMA staging TO app_dev;
GRANT USAGE, CREATE ON SCHEMA prod TO app_dev;

-- STAGING
GRANT USAGE, CREATE ON SCHEMA staging TO app_staging;
GRANT USAGE, CREATE ON SCHEMA prod TO app_staging;
GRANT USAGE, CREATE ON SCHEMA dev TO app_staging;

-- PROD
GRANT USAGE, CREATE ON SCHEMA prod TO app_prod;
GRANT USAGE, CREATE ON SCHEMA staging TO app_prod;
GRANT USAGE, CREATE ON SCHEMA dev TO app_prod;

ALTER ROLE app_dev SET search_path = dev;
ALTER ROLE app_staging SET search_path = staging;
ALTER ROLE app_prod SET search_path = prod;

-- (Optionnel) pour exécuter ensuite avec le bon rôle:

-- =========================
-- Tables DEV
-- =========================

-- (Optionnel) exécuter ensuite avec le bon rôle:
-- psql -U app_dev -d voiture_reservation;

SET search_path TO dev;

-- Remplacement de hotel par lieu
CREATE TABLE lieu (
	id SERIAL PRIMARY KEY,
	code VARCHAR(50),
	libelle VARCHAR(255)
);

-- Ancienne table reservation modifiée
CREATE TABLE reservation (
	id SERIAL PRIMARY KEY,
	idClient VARCHAR(50) NOT NULL,
	nbPassager INTEGER NOT NULL,
	idLieu INTEGER NOT NULL REFERENCES lieu(id),
	dateArrivee TIMESTAMP NOT NULL
);

-- Nouvelles tables
CREATE TABLE parametre (
	id SERIAL PRIMARY KEY,
	vitesseMoyenne INTEGER NOT NULL,
	tempsAttente INTEGER NOT NULL
);

CREATE TABLE distance (
	id SERIAL PRIMARY KEY,
	"from" INTEGER NOT NULL REFERENCES lieu(id),
	"to" INTEGER NOT NULL REFERENCES lieu(id),
	km NUMERIC NOT NULL,
	CONSTRAINT distance_from_to_check CHECK ("from" <> "to")
);

-- Une seule ligne par paire (A,B) == (B,A)
CREATE UNIQUE INDEX distance_unique_pair
	ON distance (LEAST("from", "to"), GREATEST("from", "to"));

-- Tables déjà existantes (vehicule/token)
CREATE TABLE vehicule (
	id SERIAL PRIMARY KEY,
	reference VARCHAR(100) NOT NULL,
	nbrPlace INTEGER NOT NULL,
	typeCarburant VARCHAR(2) NOT NULL,
	CONSTRAINT vehicule_nbrPlace_check CHECK (nbrPlace > 0),
	CONSTRAINT vehicule_typeCarburant_check CHECK (typeCarburant IN ('D', 'ES', 'H'))
);

-- Token UUID généré côté Java
CREATE TABLE token (
	id SERIAL PRIMARY KEY,
	token UUID NOT NULL,
	date_expiration TIMESTAMP NOT NULL
);

-- =========================
-- Tables STAGING
-- =========================

CREATE TABLE staging.lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE staging.parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE staging.vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE staging.token (LIKE dev.token INCLUDING ALL);
CREATE TABLE staging.reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE staging.distance (LIKE dev.distance INCLUDING ALL);

CREATE UNIQUE INDEX IF NOT EXISTS distance_unique_pair
	ON staging.distance (LEAST("from", "to"), GREATEST("from", "to"));

-- =========================
-- Tables PROD
-- =========================

CREATE TABLE prod.lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE prod.parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE prod.vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE prod.token (LIKE dev.token INCLUDING ALL);
CREATE TABLE prod.reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE prod.distance (LIKE dev.distance INCLUDING ALL);

CREATE UNIQUE INDEX IF NOT EXISTS distance_unique_pair
	ON prod.distance (LEAST("from", "to"), GREATEST("from", "to"));


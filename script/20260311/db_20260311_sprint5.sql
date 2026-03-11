-- Script de création des tables SPRINT 5
-- Date: 2026-03-11
-- Crée la structure complète de la base

-- =============================
-- 1. CONNEXION À POSTGRES
-- =============================
\c postgres;

-- =============================
-- 2. DROP BASE EXISTANTE
-- =============================
DROP DATABASE IF EXISTS voiture_reservation_sprint5;

-- =============================
-- 3. CRÉER LA BASE
-- =============================
CREATE DATABASE voiture_reservation_sprint5;

\c voiture_reservation_sprint5;

-- =============================
-- 4. CRÉER LES RÔLES
-- =============================
DROP ROLE IF EXISTS app_dev CASCADE;
DROP ROLE IF EXISTS app_staging CASCADE;
DROP ROLE IF EXISTS app_prod CASCADE;

CREATE ROLE app_dev LOGIN PASSWORD 'dev_pwd';
CREATE ROLE app_staging LOGIN PASSWORD 'staging_pwd';
CREATE ROLE app_prod LOGIN PASSWORD 'prod_pwd';

-- =============================
-- 5. CRÉER LES SCHÉMAS
-- =============================
CREATE SCHEMA dev;
CREATE SCHEMA staging;
CREATE SCHEMA prod;

-- =============================
-- 6. DONNER LES DROITS SUR LES SCHÉMAS
-- =============================

-- DEV
GRANT USAGE ON SCHEMA dev TO app_dev;
GRANT CREATE ON SCHEMA dev TO app_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA dev GRANT ALL ON TABLES TO app_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA dev GRANT ALL ON SEQUENCES TO app_dev;

-- STAGING
GRANT USAGE ON SCHEMA staging TO app_staging;
GRANT CREATE ON SCHEMA staging TO app_staging;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT ALL ON TABLES TO app_staging;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT ALL ON SEQUENCES TO app_staging;

-- PROD
GRANT USAGE ON SCHEMA prod TO app_prod;
GRANT CREATE ON SCHEMA prod TO app_prod;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT ALL ON TABLES TO app_prod;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT ALL ON SEQUENCES TO app_prod;

-- =============================
-- 7. TABLES SCHÉMA DEV
-- =============================

SET search_path TO dev;

-- TYPE_LIEU
CREATE TABLE type_lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL
);

-- LIEU
CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    idTypeLieu INTEGER REFERENCES type_lieu(id)
);

-- PARAMETRE
CREATE TABLE parametre (
    id SERIAL PRIMARY KEY,
    vitesseMoyenne INTEGER NOT NULL,
    tempsAttente INTEGER NOT NULL
);

-- DISTANCE
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

-- VÉHICULE
CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nbrPlace INTEGER NOT NULL,
    typeCarburant VARCHAR(2) NOT NULL,
    CONSTRAINT vehicule_nbrPlace_check CHECK (nbrPlace > 0),
    CONSTRAINT vehicule_typeCarburant_check CHECK (typeCarburant IN ('D', 'ES', 'H'))
);

-- RESERVATION
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    idClient VARCHAR(50) NOT NULL,
    nbPassager INTEGER NOT NULL,
    idLieu INTEGER NOT NULL REFERENCES lieu(id),
    dateArrivee TIMESTAMP NOT NULL
);

-- TOKEN
CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token UUID NOT NULL,
    date_expiration TIMESTAMP NOT NULL
);

-- =============================
-- 8. TABLES SCHÉMA STAGING
-- =============================

SET search_path TO staging;

CREATE TABLE type_lieu (LIKE dev.type_lieu INCLUDING ALL);
CREATE TABLE lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE distance (LIKE dev.distance INCLUDING ALL);
CREATE TABLE token (LIKE dev.token INCLUDING ALL);

CREATE UNIQUE INDEX distance_unique_pair
    ON distance (LEAST("from", "to"), GREATEST("from", "to"));

-- =============================
-- 9. TABLES SCHÉMA PROD
-- =============================

SET search_path TO prod;

CREATE TABLE type_lieu (LIKE dev.type_lieu INCLUDING ALL);
CREATE TABLE lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE vehicule (LIKE dev.vehicule INCLUDING ALL);
CREATE TABLE reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE distance (LIKE dev.distance INCLUDING ALL);
CREATE TABLE token (LIKE dev.token INCLUDING ALL);

CREATE UNIQUE INDEX distance_unique_pair
    ON distance (LEAST("from", "to"), GREATEST("from", "to"));

-- =============================
-- 10. ACCORDER LES DROITS (DEV)
-- =============================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dev TO app_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dev TO app_dev;

-- =============================
-- 11. ACCORDER LES DROITS (STAGING)
-- =============================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staging TO app_staging;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA staging TO app_staging;

-- =============================
-- 12. ACCORDER LES DROITS (PROD)
-- =============================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA prod TO app_prod;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA prod TO app_prod;

-- =============================
-- VÉRIFICATION FINALE
-- =============================

SELECT '=== TABLES CRÉÉES ===' AS info;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'dev' ORDER BY table_name;

SELECT '=== DROITS APP_DEV ===' AS info;
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'dev' AND grantee = 'app_dev'
ORDER BY table_name, privilege_type LIMIT 10;
-- Script de migration: Ajout de la table type_lieu
-- Date: 2026-03-04
-- Objectif: Permettre la gestion de plusieurs aéroports et distinguer les types de lieux

\c voiture_reservation;

-- ===========================================
-- 1. CRÉATION DE LA TABLE type_lieu (3 schémas)
-- ===========================================

-- DEV
SET search_path TO dev;
CREATE TABLE IF NOT EXISTS type_lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL
);

-- STAGING
SET search_path TO staging;
CREATE TABLE IF NOT EXISTS type_lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL
);

-- PROD
SET search_path TO prod;
CREATE TABLE IF NOT EXISTS type_lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL
);

-- ===========================================
-- 2. AJOUT DE LA COLONNE idTypeLieu DANS lieu (3 schémas)
-- ===========================================

ALTER TABLE dev.lieu ADD COLUMN IF NOT EXISTS idTypeLieu INTEGER REFERENCES dev.type_lieu(id);
ALTER TABLE staging.lieu ADD COLUMN IF NOT EXISTS idTypeLieu INTEGER REFERENCES staging.type_lieu(id);
ALTER TABLE prod.lieu ADD COLUMN IF NOT EXISTS idTypeLieu INTEGER REFERENCES prod.type_lieu(id);

-- ===========================================
-- 3. INSERTION DES TYPES DE LIEUX (3 schémas)
-- ===========================================

-- DEV
INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel')
ON CONFLICT (code) DO NOTHING;

-- STAGING
INSERT INTO staging.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel')
ON CONFLICT (code) DO NOTHING;

-- PROD
INSERT INTO prod.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel')
ON CONFLICT (code) DO NOTHING;

-- ===========================================
-- 4. MISE À JOUR DES LIEUX EXISTANTS (3 schémas)
-- ===========================================

-- DEV
UPDATE dev.lieu SET idTypeLieu = (SELECT id FROM dev.type_lieu WHERE code = 'AEROPORT')
    WHERE code = 'AERO';
UPDATE dev.lieu SET idTypeLieu = (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL')
    WHERE code IN ('COLB', 'NOVO', 'IBIS', 'LOKA', 'CARL');

-- STAGING
UPDATE staging.lieu SET idTypeLieu = (SELECT id FROM staging.type_lieu WHERE code = 'AEROPORT')
    WHERE code = 'AERO';
UPDATE staging.lieu SET idTypeLieu = (SELECT id FROM staging.type_lieu WHERE code = 'HOTEL')
    WHERE code IN ('COLB', 'NOVO', 'IBIS', 'LOKA', 'CARL');

-- PROD
UPDATE prod.lieu SET idTypeLieu = (SELECT id FROM prod.type_lieu WHERE code = 'AEROPORT')
    WHERE code = 'AERO';
UPDATE prod.lieu SET idTypeLieu = (SELECT id FROM prod.type_lieu WHERE code = 'HOTEL')
    WHERE code IN ('COLB', 'NOVO', 'IBIS', 'LOKA', 'CARL');

-- ===========================================
-- 5. DROITS SUR LA NOUVELLE TABLE
-- ===========================================

GRANT ALL PRIVILEGES ON dev.type_lieu TO app_dev;
GRANT ALL PRIVILEGES ON dev.type_lieu_id_seq TO app_dev;

GRANT ALL PRIVILEGES ON staging.type_lieu TO app_staging;
GRANT ALL PRIVILEGES ON staging.type_lieu_id_seq TO app_staging;

GRANT ALL PRIVILEGES ON prod.type_lieu TO app_prod;
GRANT ALL PRIVILEGES ON prod.type_lieu_id_seq TO app_prod;

-- ===========================================
-- VÉRIFICATION
-- ===========================================
SELECT 'DEV - TYPE_LIEU' AS schema_table, count(*) FROM dev.type_lieu;
SELECT 'STAGING - TYPE_LIEU' AS schema_table, count(*) FROM staging.type_lieu;
SELECT 'PROD - TYPE_LIEU' AS schema_table, count(*) FROM prod.type_lieu;

SELECT 'Lieux avec type' AS info, l.code, l.libelle, t.code as type_code 
FROM dev.lieu l 
LEFT JOIN dev.type_lieu t ON l.idTypeLieu = t.id;




--RESAKA DROIT AM BASE DE DONNEE RAHA MISY ERREURS
-- Se connecter à la base
\c voiture_reservation;

-- Accorder les droits sur le schéma dev
GRANT USAGE ON SCHEMA dev TO app_dev;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dev TO app_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dev TO app_dev;

-- Vérifier
SELECT grantee, table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE table_schema = 'dev' AND grantee = 'app_dev';

-- Script de migration SPRINT 6
-- Date: 2026-03-16
-- Objectif: Créer la table assignation (avec colonne 'decalee') dans les 3 schémas

\c voiture_reservation_sprint5;

-- =============================
-- 1. (SÉCURITÉ) SUPPRESSION SI DÉJÀ EXISTANT
-- =============================

DROP TABLE IF EXISTS dev.assignation CASCADE;
DROP TABLE IF EXISTS staging.assignation CASCADE;
DROP TABLE IF EXISTS prod.assignation CASCADE;

DROP SEQUENCE IF EXISTS dev.assignation_id_seq CASCADE;
DROP SEQUENCE IF EXISTS staging.assignation_id_seq CASCADE;
DROP SEQUENCE IF EXISTS prod.assignation_id_seq CASCADE;

-- =============================
-- 2. CRÉATION TABLE ASSIGNATION - SCHÉMA DEV
-- =============================

SET search_path TO dev;

CREATE TABLE assignation (
    id SERIAL PRIMARY KEY,
    idVehicule INTEGER NOT NULL REFERENCES vehicule(id),
    idReservation INTEGER NOT NULL REFERENCES reservation(id),
    decalee BOOLEAN NOT NULL DEFAULT FALSE,
    datePlanification TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================
-- 3. CRÉATION TABLE ASSIGNATION - SCHÉMA STAGING
-- =============================

SET search_path TO staging;

CREATE TABLE assignation (LIKE dev.assignation INCLUDING ALL);

-- Correction séquence staging
CREATE SEQUENCE IF NOT EXISTS staging.assignation_id_seq;
ALTER TABLE staging.assignation ALTER COLUMN id SET DEFAULT nextval('staging.assignation_id_seq');
ALTER SEQUENCE staging.assignation_id_seq OWNED BY staging.assignation.id;

-- =============================
-- 4. CRÉATION TABLE ASSIGNATION - SCHÉMA PROD
-- =============================

SET search_path TO prod;

CREATE TABLE assignation (LIKE dev.assignation INCLUDING ALL);

-- Correction séquence prod
CREATE SEQUENCE IF NOT EXISTS prod.assignation_id_seq;
ALTER TABLE prod.assignation ALTER COLUMN id SET DEFAULT nextval('prod.assignation_id_seq');
ALTER SEQUENCE prod.assignation_id_seq OWNED BY prod.assignation.id;

-- =============================
-- 5. DROITS POUR LES RÔLES
-- =============================

GRANT ALL PRIVILEGES ON TABLE dev.assignation TO app_dev;
GRANT ALL PRIVILEGES ON SEQUENCE dev.assignation_id_seq TO app_dev;

GRANT ALL PRIVILEGES ON TABLE staging.assignation TO app_staging;
GRANT ALL PRIVILEGES ON SEQUENCE staging.assignation_id_seq TO app_staging;

GRANT ALL PRIVILEGES ON TABLE prod.assignation TO app_prod;
GRANT ALL PRIVILEGES ON SEQUENCE prod.assignation_id_seq TO app_prod;

-- =============================
-- 6. VÉRIFICATION (OPTIONNELLE)
-- =============================
-- À exécuter manuellement si besoin dans psql :
--   \d+ dev.assignation;
--   \d+ staging.assignation;
--   \d+ prod.assignation;
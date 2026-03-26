-- ============================================================
-- SPRINT 7 : Colonne nbPassagerAffecte pour fractionnement
-- ============================================================

-- ============================================================
-- DEV
-- ============================================================

\c voiture_reservation_sprint5;

set search_path to dev;

ALTER TABLE dev.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE dev.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM dev.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE dev.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE dev.assignation ADD CONSTRAINT assignation_nbpassageraffe_check CHECK (nbPassagerAffecte > 0);

-- ============================================================
-- STAGING
-- ============================================================
ALTER TABLE staging.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE staging.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM staging.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE staging.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE staging.assignation ADD CONSTRAINT assignation_nbpassageraffe_check_staging CHECK (nbPassagerAffecte > 0);

-- ============================================================
-- PROD
-- ============================================================
ALTER TABLE prod.assignation ADD COLUMN IF NOT EXISTS nbPassagerAffecte INTEGER;

UPDATE prod.assignation a
SET nbPassagerAffecte = r.nbPassager
FROM prod.reservation r
WHERE a.idReservation = r.id
  AND a.nbPassagerAffecte IS NULL;

ALTER TABLE prod.assignation ALTER COLUMN nbPassagerAffecte SET NOT NULL;
ALTER TABLE prod.assignation ADD CONSTRAINT assignation_nbpassageraffe_check_prod CHECK (nbPassagerAffecte > 0);


ALTER TABLE dev.vehicule ADD COLUMN heureDisponibilite TIME;

-- Exemple de données
UPDATE dev.vehicule SET heureDisponibilite = '08:00:00' WHERE id = 1;
UPDATE dev.vehicule SET heureDisponibilite = '10:00:00' WHERE id = 2;
UPDATE dev.vehicule SET heureDisponibilite = '14:00:00' WHERE id = 3;
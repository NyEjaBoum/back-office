-- ==============================================================================
-- MIGRATION : Ajout du champ heureDisponibilite dans la table vehicule
-- Date : 2026-03-19
--
-- Objectif : Permettre de définir une heure de disponibilité initiale pour chaque véhicule
-- ==============================================================================

\c voiture_reservation_sprint5;

set search_path to dev;

-- Ajouter la colonne heureDisponibilite (nullable)
ALTER TABLE dev.vehicule ADD COLUMN IF NOT EXISTS heureDisponibilite TIMESTAMP;

-- Par défaut, tous les véhicules sont disponibles dès le début de la journée
-- (NULL signifie pas de restriction)
UPDATE dev.vehicule SET heureDisponibilite = NULL WHERE heureDisponibilite IS NULL;

COMMENT ON COLUMN dev.vehicule.heureDisponibilite IS 'Date et heure à partir de laquelle le véhicule est disponible (NULL = toujours disponible)';

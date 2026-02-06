-- Script d'insertion des hôtels de test
-- Date: 2026-02-06
-- Description: Ajouter des données de test pour les hôtels

-- Se connecter à la base de données
\c voiture_reservation;

-- Insérer des hôtels dans le schéma dev
INSERT INTO dev.hotel (nom) VALUES 
    ('Grand Hôtel Paris'),
    ('Hôtel de la Plage'),
    ('Le Majestic'),
    ('Hôtel du Soleil'),
    ('Villa Paradis'),
    ('Hôtel Royal'),
    ('Le Méditerranée'),
    ('Hôtel des Alpes');

-- Copier les données vers staging et prod si nécessaire
INSERT INTO staging.hotel (nom) SELECT nom FROM dev.hotel;
INSERT INTO prod.hotel (nom) SELECT nom FROM dev.hotel;

-- Vérification
SELECT * FROM dev.hotel;

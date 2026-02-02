-- fichier: creation_base_gestion_voiture.sql

CREATE DATABASE IF NOT EXISTS gestion_voiture;
USE gestion_voiture;

-- Table des propriétaires
CREATE TABLE proprietaire (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    adresse VARCHAR(255),
    telephone VARCHAR(20)
);

-- Table des voitures
CREATE TABLE voiture (
    id INT AUTO_INCREMENT PRIMARY KEY,
    marque VARCHAR(50) NOT NULL,
    modele VARCHAR(50) NOT NULL,
    annee INT,
    immatriculation VARCHAR(20) UNIQUE NOT NULL,
    proprietaire_id INT,
    FOREIGN KEY (proprietaire_id) REFERENCES proprietaire(id)
);

-- Table des entretiens
CREATE TABLE entretien (
    id INT AUTO_INCREMENT PRIMARY KEY,
    voiture_id INT,
    date_entretien DATE NOT NULL,
    description TEXT,
    cout DECIMAL(10,2),
    FOREIGN KEY (voiture_id) REFERENCES voiture(id)
);
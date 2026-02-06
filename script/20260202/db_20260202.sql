-- ============================================
-- PROJET Mr NAINA - Reservation Voiture
-- Script d'initialisation de la base de donnees
-- ============================================

\c postgres

-- Creation ou recreation de la base de donnees
DROP DATABASE IF EXISTS car_db;
CREATE DATABASE car_db;

\c car_db;

-- 1. Table: Type de carburant
CREATE TABLE type_carburant (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table: Hotel
CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    adresse TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- 3. Table: Priorite d'assignation
CREATE TABLE priorite_assignation (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(100) NOT NULL,
    description TEXT,
    actif BOOLEAN DEFAULT FALSE,
    ordre INT
);

-- 4. Table: Statut
CREATE TABLE statut (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    libelle VARCHAR(100) NOT NULL,
    ordre INT NOT NULL,
    actif BOOLEAN DEFAULT TRUE,
    UNIQUE(type, code)
);

-- 5. Table: Voiture
CREATE TABLE voiture (
    id SERIAL PRIMARY KEY,
    immatriculation VARCHAR(20) NOT NULL UNIQUE,
    marque VARCHAR(50),
    modele VARCHAR(50),
    capacite INT NOT NULL CHECK (capacite > 0),
    type_carburant_id INT REFERENCES type_carburant(id),
    disponible BOOLEAN DEFAULT TRUE
);

-- 6. Table: Client
CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Table: Reservation
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id),
    nombre_personnes INT NOT NULL CHECK (nombre_personnes > 0),
    heure_arrivee TIMESTAMP NOT NULL,
    hotel_id INT REFERENCES hotel(id),
    numero_vol VARCHAR(20),
    statut_id INT REFERENCES statut(id) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Table: Affectation de voiture
CREATE TABLE affectation_voiture (
    id SERIAL PRIMARY KEY,
    voiture_id INT REFERENCES voiture(id),
    reservation_id INT REFERENCES reservation(id),
    ordre_passage INT,
    heure_depart TIMESTAMP,
    heure_arrivee_estimee TIMESTAMP,
    heure_arrivee_reelle TIMESTAMP,
    distance_km DECIMAL(10, 2),
    statut_id INT REFERENCES statut(id) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(reservation_id)
);

-- 9. Table: Parametres systeme
CREATE TABLE parametre_systeme (
    id SERIAL PRIMARY KEY,
    cle VARCHAR(100) NOT NULL UNIQUE,
    valeur VARCHAR(255) NOT NULL,
    description TEXT
);

-- ============================================
-- INDEX pour optimisation
-- ============================================
CREATE INDEX idx_reservation_heure_arrivee ON reservation(heure_arrivee);
CREATE INDEX idx_reservation_statut ON reservation(statut_id);
CREATE INDEX idx_voiture_disponible ON voiture(disponible);
CREATE INDEX idx_affectation_statut ON affectation_voiture(statut_id);
CREATE INDEX idx_priorite_actif ON priorite_assignation(actif);
CREATE INDEX idx_statut_type ON statut(type);

-- ============================================
-- DONNEES INITIALES
-- ============================================

-- 1. Types de carburant
INSERT INTO type_carburant (libelle) VALUES 
('Essence'),
('Diesel'),
('Electrique'),
('Hybride');

-- 2. Hotels
INSERT INTO hotel (nom, adresse, latitude, longitude) VALUES
('Hotel Carlton', 'Avenue de lIndependance Antananarivo', -18.9100, 47.5250),
('Radisson Blu', 'Rue Ravoninahitriniarivo Antananarivo', -18.9150, 47.5300),
('Hotel Colbert', 'Rue Printsy Ratsimamanga Antananarivo', -18.9120, 47.5270);

-- 3. Priorites dassignation
INSERT INTO priorite_assignation (code, libelle, description, actif, ordre) VALUES
('CAPACITE_MIN', 'Capacite minimale', 'Choisir la voiture avec la plus petite capacite suffisante', TRUE, 1),
('CAPACITE_MAX', 'Capacite maximale', 'Choisir la voiture avec la plus grande capacite', FALSE, 2),
('MOINS_TRAJETS', 'Moins de trajets', 'Choisir la voiture ayant effectue le moins de trajets', FALSE, 3),
('DISPONIBILITE', 'Premiere disponible', 'Choisir la premiere voiture disponible', FALSE, 4);

-- 4. Statuts
INSERT INTO statut (type, code, libelle, ordre) VALUES
('RESERVATION', 'EN_ATTENTE', 'En attente', 10),
('RESERVATION', 'ASSIGNEE', 'Assignee', 20),
('RESERVATION', 'EN_COURS', 'En cours', 30),
('RESERVATION', 'TERMINEE', 'Terminee', 40),
('RESERVATION', 'ANNULEE', 'Annulee', 50),
('AFFECTATION', 'PLANIFIE', 'Planifie', 10),
('AFFECTATION', 'EN_COURS', 'En cours', 20),
('AFFECTATION', 'TERMINE', 'Termine', 30),
('AFFECTATION', 'ANNULE', 'Annule', 40);

-- 5. Voitures
INSERT INTO voiture (immatriculation, marque, modele, capacite, type_carburant_id) VALUES
('1234 TAA', 'Toyota', 'Hiace', 15, 2),
('5678 TAB', 'Mercedes', 'Sprinter', 12, 2),
('9012 TAC', 'Renault', 'Master', 9, 2),
('3456 TAD', 'Peugeot', '308', 5, 1),
('7890 TAE', 'Toyota', 'Corolla', 4, 3);

-- 6. Clients de test
INSERT INTO client (nom, prenom, telephone, email) VALUES
('RAKOTO', 'Jean', '+261 34 12 345 67', 'rakoto@email.mg'),
('RASOA', 'Marie', '+261 33 98 765 43', 'rasoa@email.mg'),
('RABE', 'Paul', '+261 32 55 123 45', 'rabe@email.mg');

-- 7. Parametres systeme
INSERT INTO parametre_systeme (cle, valeur, description) VALUES
('VITESSE_MOYENNE_KMH', '20', 'Vitesse moyenne des voitures en kmh'),
('TEMPS_ATTENTE_MAX_MIN', '30', 'Temps dattente maximum accepte pour regroupement en minutes'),
('HEURE_RESET_TRAJETS', '0600', 'Heure de remise a zero des trajets format HHMM');
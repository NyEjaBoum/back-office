-- ============================================
-- PROJET Mr NAINA - Reservation Voiture
-- Initialisation base + schemas
-- ============================================

\c postgres;

-- Recréation de la base
DROP DATABASE IF EXISTS car_db;
CREATE DATABASE car_db;

\c car_db;

CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    adresse TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);


-- 7. Reservation
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    client_id TEXT,
    nombre_personnes INT NOT NULL CHECK (nombre_personnes > 0),
    heure_arrivee TIMESTAMP NOT NULL,
    hotel_id INT REFERENCES hotel(id)
);



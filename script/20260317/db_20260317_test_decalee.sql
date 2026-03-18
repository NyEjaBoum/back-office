


-- ==============================================================================
-- TEST DECALEE — SPRINT 6 : REPORT AU GROUPE SUIVANT
-- Date : 2026-03-17
--
-- Ce script teste specifiquement le cas ou une reservation est reportee
-- d'un groupe horaire a un autre (tag DECALEE).
--
-- Vitesse moyenne : 40 km/h
-- Temps d'attente (fenetre de groupe) : 30 min
-- Date de test : 2026-04-02
-- ==============================================================================

-- ==================== NETTOYAGE ====================
TRUNCATE dev.assignation  RESTART IDENTITY CASCADE;
TRUNCATE dev.reservation  RESTART IDENTITY CASCADE;
TRUNCATE dev.distance     RESTART IDENTITY CASCADE;
TRUNCATE dev.vehicule     RESTART IDENTITY CASCADE;
TRUNCATE dev.lieu         RESTART IDENTITY CASCADE;
TRUNCATE dev.type_lieu    RESTART IDENTITY CASCADE;
TRUNCATE dev.parametre    RESTART IDENTITY CASCADE;

-- ==================== TYPE LIEU ====================
INSERT INTO dev.type_lieu (id, code, libelle) VALUES
    (1, 'AEROPORT', 'Aeroport'),
    (2, 'HOTEL',    'Hotel');

-- ==================== LIEUX ====================
INSERT INTO dev.lieu (id, code, libelle, idTypeLieu) VALUES
    (1, 'AERO', 'Aeroport', 1),
    (2, 'COLB', 'Colbert',  2),
    (3, 'LOKA', 'Lokanga',  2);

-- ==================== PARAMETRE ====================
INSERT INTO dev.parametre (id, vitesseMoyenne, tempsAttente) VALUES
    (1, 40, 30);

-- ==================== VEHICULES ====================
-- Un seul vehicule pour forcer la saturation et le report
INSERT INTO dev.vehicule (id, reference, nbrPlace, typeCarburant) VALUES
    (1, 'VAN-D', 8, 'D');

-- ==================== DISTANCES ====================
-- Distances longues pour que le vehicule soit occupe longtemps
--
--             AERO   COLB   LOKA
--   AERO       -      15     20
--   COLB      15       -     10
--   LOKA      20      10      -
INSERT INTO dev.distance ("from", "to", km) VALUES
    (1, 2, 15.0),   -- AERO <-> COLB
    (1, 3, 20.0),   -- AERO <-> LOKA
    (2, 3, 10.0);   -- COLB <-> LOKA

-- ==================== RESERVATIONS ====================
-- 2 groupes horaires, 1 seul vehicule (8 places)
INSERT INTO dev.reservation (id, idClient, nbPassager, idLieu, dateArrivee) VALUES
    -- ---------------------------------------------------------------
    -- GROUPE 1 : arrivees 08:00 - 08:10 (fenetre 30 min)
    -- 2 reservations qui remplissent le vehicule
    -- ---------------------------------------------------------------
    (1, 'C01', 5, 2, '2026-04-02 08:00:00'),  -- 5 pass -> Colbert
    (2, 'C02', 3, 3, '2026-04-02 08:10:00'),  -- 3 pass -> Lokanga

    -- ---------------------------------------------------------------
    -- Toujours dans GROUPE 1 (08:20 est dans la fenetre de 08:10)
    -- MAIS le vehicule est deja plein (5+3=8) → R3 ne rentre pas
    -- ---------------------------------------------------------------
    (3, 'C03', 4, 2, '2026-04-02 08:20:00'),  -- 4 pass -> Colbert

    -- ---------------------------------------------------------------
    -- GROUPE 2 : arrivee 10:00
    -- Le vehicule sera de retour, et R3 (decalee) sera aussi ici
    -- ---------------------------------------------------------------
    (4, 'C04', 2, 3, '2026-04-02 10:00:00');  -- 2 pass -> Lokanga

-- Reset des sequences
SELECT setval('dev.type_lieu_id_seq', (SELECT MAX(id) FROM dev.type_lieu));
SELECT setval('dev.lieu_id_seq', (SELECT MAX(id) FROM dev.lieu));
SELECT setval('dev.vehicule_id_seq', (SELECT MAX(id) FROM dev.vehicule));
SELECT setval('dev.distance_id_seq', (SELECT MAX(id) FROM dev.distance));
SELECT setval('dev.reservation_id_seq', (SELECT MAX(id) FROM dev.reservation));
SELECT setval('dev.parametre_id_seq', (SELECT MAX(id) FROM dev.parametre));


-- ==============================================================================
-- RESULTATS ATTENDUS
-- ==============================================================================
--
-- ======================================================================
-- GROUPE 1 — Heure depart : 2026-04-02 08:20:00 (derniere arrivee)
--            Fenetre : 08:20 → 08:50
-- ======================================================================
-- Reservations triees par nbPassager DESC :
--   R1 : 5 pass -> Colbert
--   R3 : 4 pass -> Colbert
--   R2 : 3 pass -> Lokanga
--
-- Passage 1 (heureDepartEffective = 08:20) :
--   Vehicules disponibles : VAN-D (8 places)
--
--   R1 (5 pass) : nouveau vehicule VAN-D(8) → OK
--     Places restantes VAN-D : 8 - 5 = 3
--
--   R3 (4 pass) : VAN-D deja utilise, 3 places < 4 → KO.
--     Pas de nouveau vehicule disponible → non assignee.
--
--   R2 (3 pass) : VAN-D deja utilise, 3 places >= 3 → OK
--     Places restantes VAN-D : 3 - 3 = 0
--
--   Trajet passage 1 :
--     VAN-D : Colbert + Lokanga
--       Greedy : AERO -> Colbert(15) -> Lokanga(10) -> AERO(20) = 45 km
--       Retour = 08:20 + (45/40)*60 = 08:20 + 67.5 min = 09:27:30
--
--   R3 non assignee. Vehicule qui revient dans la fenetre [08:20, 08:50] ?
--     VAN-D retour 09:27:30 > 08:50 → NON
--     → Aucun vehicule ne revient dans la fenetre
--
--   *** R3 est REPORTEE au groupe suivant → R3.decalee = true ***
--
-- ======================================================================
-- GROUPE 2 — Heure depart : 2026-04-02 10:00:00
--            Fenetre : 10:00 → 10:30
-- ======================================================================
-- Reservations = R4 (du groupe) + R3 (reportee, decalee=true)
-- Triees par nbPassager DESC :
--   R3 : 4 pass -> Colbert  [DECALEE]
--   R4 : 2 pass -> Lokanga
--
-- Passage 1 (heureDepartEffective = 10:00) :
--   Vehicules disponibles (heureRetour <= 10:00) :
--     VAN-D : retour 09:27:30 <= 10:00 → disponible (8 places)
--
--   R3 (4 pass, DECALEE) : nouveau vehicule VAN-D(8) → OK
--     Places restantes VAN-D : 8 - 4 = 4
--
--   R4 (2 pass) : VAN-D deja utilise, 4 places >= 2 → OK
--     Places restantes VAN-D : 4 - 2 = 2
--
--   Trajet passage 1 :
--     VAN-D : Colbert + Lokanga
--       Greedy : AERO -> Colbert(15) -> Lokanga(10) -> AERO(20) = 45 km
--       Retour = 10:00 + 67.5 min = 11:07:30
--
--   Tout assigne → sortie de boucle.
--
-- ======================================================================
-- RESUME FINAL ATTENDU
-- ======================================================================
--
-- TRAJETS :
-- | # | Vehicule | Reservations              | Depart | Retour  | Dist   |
-- |---|----------|---------------------------|--------|---------|--------|
-- | 1 | VAN-D    | R1(5p,Colb)+R2(3p,Loka)   | 08:20  | ~09:27  | 45 km  |
-- | 2 | VAN-D    | R3(4p,Colb)+R4(2p,Loka)   | 10:00  | ~11:07  | 45 km  |
--
-- NON ASSIGNEES : aucune
--
-- ASSIGNATIONS EN BASE :
-- | idVehicule | idReservation | decalee |
-- |------------|---------------|---------|
-- | 1 (VAN-D)  | 1 (R1)        | false   |
-- | 1 (VAN-D)  | 2 (R2)        | false   |
-- | 1 (VAN-D)  | 3 (R3)        | TRUE    |  ← reportee du groupe 1 au groupe 2
-- | 1 (VAN-D)  | 4 (R4)        | false   |
--
-- AFFICHAGE ATTENDU EN UI :
--
--   GROUPE 08:20 — VAN-D (8 places · Diesel)
--     Colbert  | 5 pass. | 08:00
--     Lokanga  | 3 pass. | 08:10
--
--   GROUPE 10:00 — VAN-D (8 places · Diesel)
--     Colbert  | 4 pass. | 08:20  [DECALEE]    ← tag visible
--     Lokanga  | 2 pass. | 10:00
--
-- REGLES VALIDEES :
--   [DECALEE]  R3 reportee du groupe 1 au groupe 2 car vehicule indisponible
--   [TAG UI]   R3 affichee avec le badge "DECALEE" dans le groupe 2
--   [PERSIST]  L'assignation de R3 a decalee=true en base
--   [PARTAGE]  R3 et R4 partagent le meme vehicule dans le groupe 2
--

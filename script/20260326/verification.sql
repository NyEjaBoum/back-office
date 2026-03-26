-- =====================================================
-- VERIFICATION DES RESULTATS - TEST SPRINT 8
-- =====================================================

\c voiture_reservation_sprint5;
SET search_path TO dev;

-- ===========================================
-- 1. VÉRIFICATION DES DONNÉES DE BASE
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'VERIFICATION DES DONNEES DE BASE' AS titre;
SELECT '========================================' AS separateur;

SELECT 'Total réservations' AS info, COUNT(*) AS valeur FROM reservation;
SELECT 'Total véhicules' AS info, COUNT(*) AS valeur FROM vehicule;
SELECT 'Capacité totale' AS info, SUM(nbrPlace) AS valeur FROM vehicule;

-- ===========================================
-- 2. DÉTAIL DES RÉSERVATIONS
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'DETAIL DES RESERVATIONS' AS titre;
SELECT '========================================' AS separateur;

SELECT
    r.id,
    r.idClient,
    r.nbPassager,
    l.libelle AS destination,
    TO_CHAR(r.dateArrivee, 'YYYY-MM-DD HH24:MI') AS heure_arrivee
FROM reservation r
JOIN lieu l ON r.idLieu = l.id
ORDER BY r.dateArrivee, r.nbPassager DESC;

-- ===========================================
-- 3. ASSIGNATIONS PAR VÉHICULE
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'ASSIGNATIONS PAR VEHICULE' AS titre;
SELECT '========================================' AS separateur;

SELECT
    v.reference AS vehicule,
    r.id AS id_reservation,
    r.idClient,
    r.nbPassager AS total_passagers,
    a.nbPassagerAffecte AS passagers_assignes,
    CASE WHEN a.decalee THEN 'OUI ✓' ELSE 'NON' END AS decalee,
    l.libelle AS destination,
    TO_CHAR(r.dateArrivee, 'HH24:MI') AS heure_reservation
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
JOIN vehicule v ON a.idVehicule = v.id
JOIN lieu l ON r.idLieu = l.id
WHERE DATE(r.dateArrivee) = '2026-03-26'
ORDER BY a.datePlanification, a.decalee DESC, r.dateArrivee;

-- ===========================================
-- 4. VÉRIFICATION DE LA PRIORITÉ DES DÉCALÉES
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'VERIFICATION PRIORITE DECALEES' AS titre;
SELECT '========================================' AS separateur;

SELECT
    CASE WHEN a.decalee THEN '1-DECALEE' ELSE '2-NORMALE' END AS priorite,
    v.reference AS vehicule,
    r.idClient,
    a.nbPassagerAffecte AS passagers,
    l.libelle AS destination,
    TO_CHAR(a.datePlanification, 'YYYY-MM-DD HH24:MI:SS') AS heure_planification
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
JOIN vehicule v ON a.idVehicule = v.id
JOIN lieu l ON r.idLieu = l.id
WHERE DATE(r.dateArrivee) = '2026-03-26'
ORDER BY a.datePlanification, priorite, r.dateArrivee;

-- ===========================================
-- 5. STATISTIQUES PAR VÉHICULE
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'STATISTIQUES PAR VEHICULE' AS titre;
SELECT '========================================' AS separateur;

SELECT
    v.reference AS vehicule,
    v.nbrPlace AS capacite,
    COUNT(DISTINCT a.id) AS nb_affectations,
    SUM(a.nbPassagerAffecte) AS total_passagers_affectes,
    v.nbrPlace - SUM(a.nbPassagerAffecte) AS places_restantes
FROM vehicule v
LEFT JOIN assignation a ON v.id = a.idVehicule
    AND EXISTS (
        SELECT 1 FROM reservation r
        WHERE r.id = a.idReservation
        AND DATE(r.dateArrivee) = '2026-03-26'
    )
GROUP BY v.id, v.reference, v.nbrPlace
ORDER BY v.nbrPlace DESC;

-- ===========================================
-- 6. RÉSERVATIONS FRACTIONNÉES
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'RESERVATIONS FRACTIONNEES' AS titre;
SELECT '========================================' AS separateur;

SELECT
    r.id AS id_reservation,
    r.idClient,
    r.nbPassager AS total_passagers,
    COUNT(a.id) AS nb_fractions,
    STRING_AGG(v.reference || '(' || a.nbPassagerAffecte || ')', ', ') AS repartition,
    CASE
        WHEN COUNT(a.id) > 1 THEN 'OUI - FRACTIONNEE'
        ELSE 'NON'
    END AS est_fractionnee
FROM reservation r
LEFT JOIN assignation a ON r.id = a.idReservation
LEFT JOIN vehicule v ON a.idVehicule = v.id
WHERE DATE(r.dateArrivee) = '2026-03-26'
GROUP BY r.id, r.idClient, r.nbPassager
ORDER BY r.id;

-- ===========================================
-- 7. PASSAGERS DÉCALÉS
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'PASSAGERS DECALES (PRIORITAIRES)' AS titre;
SELECT '========================================' AS separateur;

SELECT
    COUNT(*) AS nb_assignations_decalees,
    SUM(a.nbPassagerAffecte) AS total_passagers_decales,
    STRING_AGG(DISTINCT r.idClient, ', ') AS clients_concernes
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
WHERE a.decalee = TRUE
    AND DATE(r.dateArrivee) = '2026-03-26';

-- ===========================================
-- 8. VALIDATION SPRINT 8
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'VALIDATION SPRINT 8' AS titre;
SELECT '========================================' AS separateur;

-- Test 1: Il doit y avoir des assignations décalées
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS statut,
    'Test 1: Présence de réservations décalées' AS description,
    COUNT(*) AS nb_decalees
FROM assignation
WHERE decalee = TRUE
    AND EXISTS (
        SELECT 1 FROM reservation r
        WHERE r.id = idReservation
        AND DATE(r.dateArrivee) = '2026-03-26'
    );

-- Test 2: Les réservations décalées doivent avoir été traitées
SELECT
    CASE
        WHEN SUM(a.nbPassagerAffecte) >= 5 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS statut,
    'Test 2: Au moins 5 passagers décalés assignés' AS description,
    COALESCE(SUM(a.nbPassagerAffecte), 0) AS passagers_decales_assignes
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
WHERE a.decalee = TRUE
    AND DATE(r.dateArrivee) = '2026-03-26';

-- Test 3: Vérifier que tous les passagers sont assignés
SELECT
    CASE
        WHEN total_passagers = passagers_assignes THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS statut,
    'Test 3: Tous les passagers sont assignés' AS description,
    total_passagers,
    passagers_assignes,
    total_passagers - passagers_assignes AS passagers_non_assignes
FROM (
    SELECT
        SUM(r.nbPassager) AS total_passagers,
        COALESCE(SUM(a.nbPassagerAffecte), 0) AS passagers_assignes
    FROM reservation r
    LEFT JOIN assignation a ON r.id = a.idReservation
    WHERE DATE(r.dateArrivee) = '2026-03-26'
) AS stats;

-- Test 4: V20 doit avoir fait plusieurs trajets
SELECT
    CASE
        WHEN nb_trajets >= 2 THEN '✓ PASS'
        ELSE '✗ FAIL - V20 devrait avoir fait au moins 2 trajets'
    END AS statut,
    'Test 4: V20 a effectué plusieurs trajets' AS description,
    nb_trajets
FROM (
    SELECT COUNT(DISTINCT a.datePlanification) AS nb_trajets
    FROM assignation a
    JOIN vehicule v ON a.idVehicule = v.id
    JOIN reservation r ON a.idReservation = r.id
    WHERE v.reference = 'V20-DIESEL'
        AND DATE(r.dateArrivee) = '2026-03-26'
) AS trajets;

-- ===========================================
-- 9. RÉSUMÉ FINAL
-- ===========================================
SELECT '========================================' AS separateur;
SELECT 'RESUME FINAL' AS titre;
SELECT '========================================' AS separateur;

SELECT
    'Réservations totales' AS metrique,
    COUNT(DISTINCT r.id) AS valeur
FROM reservation r
WHERE DATE(r.dateArrivee) = '2026-03-26'
UNION ALL
SELECT
    'Passagers totaux' AS metrique,
    SUM(r.nbPassager) AS valeur
FROM reservation r
WHERE DATE(r.dateArrivee) = '2026-03-26'
UNION ALL
SELECT
    'Passagers assignés' AS metrique,
    COALESCE(SUM(a.nbPassagerAffecte), 0) AS valeur
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
WHERE DATE(r.dateArrivee) = '2026-03-26'
UNION ALL
SELECT
    'Assignations décalées' AS metrique,
    COUNT(*) AS valeur
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
WHERE a.decalee = TRUE
    AND DATE(r.dateArrivee) = '2026-03-26'
UNION ALL
SELECT
    'Véhicules utilisés' AS metrique,
    COUNT(DISTINCT a.idVehicule) AS valeur
FROM assignation a
JOIN reservation r ON a.idReservation = r.id
WHERE DATE(r.dateArrivee) = '2026-03-26';

package dao;

import model.Assignation;
import model.Lieu;
import model.Reservation;
import model.Vehicule;
import java.util.*;

public class PlanningDao {

    private DistanceDao distanceDao = new DistanceDao();
    private LieuDao lieuDao = new LieuDao();
    private ParametreDao parametreDao = new ParametreDao();
    private AssignationDao assignationDao = new AssignationDao();

    /**
     * Retourne la liste de tous les lieux de type AEROPORT
     */
    private List<Integer> getIdAeroports() throws Exception {
        List<Lieu> aeroports = lieuDao.findByType("AEROPORT");
        if (aeroports.isEmpty()) throw new Exception("Aucun lieu de type AEROPORT trouvé en base");
        List<Integer> ids = new ArrayList<>();
        for (Lieu l : aeroports) ids.add(l.getId());
        return ids;
    }

    /**
     * Trouve l'aéroport le plus proche d'un ensemble de lieux
     * @param lieuxIds Liste des ids de lieux (hôtels)
     * @return L'id de l'aéroport le plus proche
     */
    private int trouverAeroportLePlusProche(List<Integer> lieuxIds) throws Exception {
        List<Integer> aeroports = getIdAeroports();
        if (aeroports.size() == 1) {
            return aeroports.get(0);
        }

        int meilleurAeroport = aeroports.get(0);
        double minDistanceTotale = Double.MAX_VALUE;

        for (Integer idAeroport : aeroports) {
            double distanceTotale = 0.0;
            for (Integer idLieu : lieuxIds) {
                try {
                    double dist = distanceDao.getDistance(idAeroport, idLieu);
                    if (dist >= 0) distanceTotale += dist;
                } catch (Exception e) {
                    // Distance non trouvée, on ignore
                }
            }
            if (distanceTotale < minDistanceTotale) {
                minDistanceTotale = distanceTotale;
                meilleurAeroport = idAeroport;
            }
        }
        return meilleurAeroport;
    }

    /**
     * Calcule la distance totale (greedy nearest neighbor) pour une liste de réservations.
     * Trajet : Aeroport -> lieux -> Aeroport
     * Retourne une Map avec "distanceTotale" (Double) et "ordreTrajet" (List<String> des noms de lieux).
     * En cas d'égalité de distance, le lieu alphabétiquement le plus petit est visité en premier.
     */
    public Map<String, Object> calculerDistanceGreedy(List<Reservation> reservations) throws Exception {
        Map<String, Object> resultat = new HashMap<>();
        List<Integer> lieux = extraireLieuxUniques(reservations);
        if (lieux.isEmpty()) {
            resultat.put("distanceTotale", 0.0);
            resultat.put("ordreTrajet", new ArrayList<String>());
            return resultat;
        }

        // Map idLieu -> nomLieu pour le tri alphabétique en cas d'égalité de distance
        Map<Integer, String> nomParLieu = new HashMap<>();
        for (Reservation r : reservations) {
            if (!nomParLieu.containsKey(r.getIdLieu()) && r.getNomLieu() != null) {
                nomParLieu.put(r.getIdLieu(), r.getNomLieu());
            }
        }

        // Trouver l'aéroport le plus proche des lieux de la réservation
        int idAeroport = trouverAeroportLePlusProche(lieux);

        double total = 0.0;
        List<Integer> nonVisites = new ArrayList<>(lieux);
        List<String> ordreTrajet = new ArrayList<>();

        // Aeroport -> lieu le plus proche (alphabétique si même distance)
        Integer current = null;
        double minDist = Double.MAX_VALUE;
        String nomMin = null;
        for (Integer l : nonVisites) {
            double dist = distanceDao.getDistance(idAeroport, l);
            String nom = nomParLieu.getOrDefault(l, "");
            if (dist >= 0 && (dist < minDist || (dist == minDist && nomMin != null && nom.compareTo(nomMin) < 0))) {
                minDist = dist;
                current = l;
                nomMin = nom;
            }
        }
        if (current == null) {
            resultat.put("distanceTotale", 0.0);
            resultat.put("ordreTrajet", new ArrayList<String>());
            return resultat;
        }
        total += minDist;
        ordreTrajet.add(nomParLieu.getOrDefault(current, "Lieu #" + current));
        nonVisites.remove(current);

        // Greedy : lieu courant -> lieu le plus proche non visité (alphabétique si même distance)
        while (!nonVisites.isEmpty()) {
            Integer next = null;
            minDist = Double.MAX_VALUE;
            nomMin = null;
            for (Integer l : nonVisites) {
                double dist;
                try { dist = distanceDao.getDistance(current, l); }
                catch (Exception e) { dist = Double.MAX_VALUE; }
                String nom = nomParLieu.getOrDefault(l, "");
                if (dist >= 0 && (dist < minDist || (dist == minDist && nomMin != null && nom.compareTo(nomMin) < 0))) {
                    minDist = dist;
                    next = l;
                    nomMin = nom;
                }
            }
            if (next == null) break;
            total += minDist;
            ordreTrajet.add(nomParLieu.getOrDefault(next, "Lieu #" + next));
            current = next;
            nonVisites.remove(next);
        }

        // Dernier lieu -> Aeroport
        double retour = distanceDao.getDistance(current, idAeroport);
        if (retour >= 0) total += retour;

        resultat.put("distanceTotale", total);
        resultat.put("ordreTrajet", ordreTrajet);
        return resultat;
    }

    /** Extrait les lieux uniques d'une liste de réservations */
    private List<Integer> extraireLieuxUniques(List<Reservation> reservations) {
        List<Integer> lieux = new ArrayList<>();
        for (Reservation r : reservations) {
            if (!lieux.contains(r.getIdLieu())) {
                lieux.add(r.getIdLieu());
            }
        }
        return lieux;
    }

    /**
     * PLANIFICATION PRINCIPALE
     *
     * Traite toute la journée d'un coup :
     * - Parcourt tous les groupes horaires triés par heure
     * - Boucle interne au groupe : si un véhicule revient dans la fenêtre, on retente
     * - Report des réservations non assignées au groupe suivant (décalées)
     * - Persistance en base (table assignation)
     * - Choix véhicule : places, puis trajets, puis carburant D > ES > H
     */

    /**
     * Classe interne pour tracker une fraction de réservation assignée.
     * Permet de gérer le fractionnement : une réservation peut être divisée sur plusieurs véhicules.
     * Chaque fraction créera une ligne separate dans la table assignation.
     */
    private static class ReservationAffectee {
        private Reservation reservation;
        private int nbPassagerAffecte;  // nombre réel assigné à cette fraction

        public ReservationAffectee(Reservation reservation, int nbPassagerAffecte) {
            this.reservation = reservation;
            this.nbPassagerAffecte = nbPassagerAffecte;
        }

        public Reservation getReservation() {
            return reservation;
        }

        public int getNbPassagerAffecte() {
            return nbPassagerAffecte;
        }
    }

    /**
     * Assigne une fraction de réservation à un véhicule.
     * Cette méthode est appelée pour CHAQUE fraction (en cas de fractionnement).
     *
     * @param assignationsVol map idVehicule -> liste de fractions
     * @param placesRestantes map idVehicule -> places encore disponibles
     * @param vehiculeChoisiId id du véhicule recevant la fraction
     * @param reservation la réservation parente (peut être fractionnée)
     * @param nbPassagersAffectes nombre de passagers de cette fraction
     */
    private void assignerFraction(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            Integer vehiculeChoisiId,
            Reservation reservation,
            int nbPassagersAffectes) {
        // Initialiser la liste pour ce véhicule s'il ne l'est pas déjà
        if (!assignationsVol.containsKey(vehiculeChoisiId)) {
            assignationsVol.put(vehiculeChoisiId, new ArrayList<>());
        }

        // Ajouter la fraction à la liste du véhicule
        assignationsVol.get(vehiculeChoisiId)
                .add(new ReservationAffectee(reservation, nbPassagersAffectes));

        // Décrémenter les places restantes du véhicule
        placesRestantes.put(
                vehiculeChoisiId,
                placesRestantes.get(vehiculeChoisiId) - nbPassagersAffectes
        );
    }

    public Map<String, Object> planifier(
            String date,
            Map<String, List<Reservation>> vols,
            List<Vehicule> vehicules) throws Exception {

        // ÉTAPE 1 : Supprimer les anciennes assignations de la date
        assignationDao.supprimerParDate(date);

        double vitesseMoyenne = parametreDao.getVitesseMoyenne();
        int tempsAttente = parametreDao.getTempsAttente();

        List<Map<String, Object>> trajets = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();

        // ÉTAPE 2 : Initialiser les compteurs
        Map<Integer, String> vehiculeHeureRetour = new HashMap<>();
        Map<Integer, Integer> trajetsParVehicule = new HashMap<>();
        for (Vehicule v : vehicules) {
            trajetsParVehicule.put(v.getId(), 0);
        }
        List<Reservation> reservationsEnAttente = new ArrayList<>();

        // ÉTAPE 3 : Parcourir TOUS les groupes horaires de la journée (triés par heure)
        for (Map.Entry<String, List<Reservation>> entry : vols.entrySet()) {
            String heureDepart = entry.getKey();
            List<Reservation> reservationsGroupe = new ArrayList<>(entry.getValue());

            // Ajouter les réservations en attente des groupes précédents
            reservationsGroupe.addAll(reservationsEnAttente);
            reservationsEnAttente = new ArrayList<>();

            // Trier par nbPassager DESC (règle existante conservée)
            trierParNbPassagerDesc(reservationsGroupe);

            // Calculer l'heure de fin du groupe
            String heureFinGroupe = ajouterMinutes(heureDepart, tempsAttente);
            String heureDepartEffective = heureDepart;
            List<Reservation> nonAssigneesGroupe = new ArrayList<>(reservationsGroupe);

            // AGRÉGATION des assignations sur toutes les itérations de la boucle while
            Map<Integer, List<ReservationAffectee>> assignationsPassageAgregees = new LinkedHashMap<>();

            // BOUCLE INTERNE AU GROUPE
            while (true) {
                Map<Integer, Integer> placesRestantes = initialiserPlacesRestantes(vehicules, vehiculeHeureRetour, heureDepartEffective);
                Map<Integer, List<ReservationAffectee>> assignationsPassage = new LinkedHashMap<>();
                List<Reservation> encoreNonAssignees = new ArrayList<>();

                for (Reservation r : nonAssigneesGroupe) {
                    int reste = r.getNbPassager();

                    // ÉTAPE 1 : essayer une assignation complète
                    Integer vehiculeChoisi = chercherVehiculeDejaUtilise(assignationsPassage, placesRestantes, reste, vehicules, trajetsParVehicule);
                    if (vehiculeChoisi == null) {
                        vehiculeChoisi = chercherNouveauVehicule(assignationsPassage, placesRestantes, reste, vehicules, trajetsParVehicule);
                    }

                    if (vehiculeChoisi != null) {
                        // Assignation complète possible
                        assignerFraction(assignationsPassage, placesRestantes, vehiculeChoisi, r, reste);
                        assignationDao.insert(new Assignation(vehiculeChoisi, r.getId(), reste, r.isDecalee()));
                        reste = 0;  // tout est assigné
                    }

                    // ÉTAPE 2 : si reste > 0, fractionner sur les véhicules dispo (capacite totale DESC)
                    if (reste > 0) {
                        // Trier les véhicules disponibles par capacite totale (DESC)
                        List<Integer> vehiculesDispoParCapacite = trierVehiculesDisponiblesParCapaciteDesc(vehicules, placesRestantes);

                        for (Integer vehiculeId : vehiculesDispoParCapacite) {
                            if (reste <= 0) break;

                            int libre = placesRestantes.get(vehiculeId);
                            int qte = Math.min(reste, libre);

                            assignerFraction(assignationsPassage, placesRestantes, vehiculeId, r, qte);
                            assignationDao.insert(new Assignation(vehiculeId, r.getId(), qte, r.isDecalee()));

                            reste -= qte;
                        }
                    }

                    // ÉTAPE 3 : si reliquat, reporter au groupe suivant
                    if (reste > 0) {
                        Reservation reliquat = new Reservation();
                        reliquat.setId(r.getId());  // IMPORTANT: garder le même ID (qui existe en base)
                        reliquat.setNbPassager(reste);
                        reliquat.setIdClient(r.getIdClient());
                        reliquat.setDateArrivee(r.getDateArrivee());
                        reliquat.setIdLieu(r.getIdLieu());
                        reliquat.setNomLieu(r.getNomLieu());
                        reliquat.setDecalee(true);
                        encoreNonAssignees.add(reliquat);
                    }
                }

                // AGRÉGER les assignations de ce passage au total du groupe
                for (Map.Entry<Integer, List<ReservationAffectee>> entryPassage : assignationsPassage.entrySet()) {
                    Integer vehiculeId = entryPassage.getKey();
                    List<ReservationAffectee> fractions = entryPassage.getValue();

                    if (!assignationsPassageAgregees.containsKey(vehiculeId)) {
                        assignationsPassageAgregees.put(vehiculeId, new ArrayList<>());
                    }
                    assignationsPassageAgregees.get(vehiculeId).addAll(fractions);
                }

                // Incrémenter le compteur de trajets par véhicule
                for (Integer vehiculeId : assignationsPassage.keySet()) {
                    trajetsParVehicule.put(vehiculeId, trajetsParVehicule.get(vehiculeId) + 1);
                }

                // Vérifier si tout est assigné
                if (encoreNonAssignees.isEmpty()) {
                    break;
                }

                // Chercher le prochain véhicule qui se libère dans la fenêtre
                String plusProchaineDisponibilite = null;
                for (Map.Entry<Integer, String> retourEntry : vehiculeHeureRetour.entrySet()) {
                    String heureRetour = retourEntry.getValue();
                    if (heureRetour.compareTo(heureDepartEffective) > 0 && heureRetour.compareTo(heureFinGroupe) <= 0) {
                        if (plusProchaineDisponibilite == null || heureRetour.compareTo(plusProchaineDisponibilite) < 0) {
                            plusProchaineDisponibilite = heureRetour;
                        }
                    }
                }

                if (plusProchaineDisponibilite == null) {
                    // Aucun véhicule ne revient dans la fenêtre
                    // Reporter les non-assignées au prochain groupe (décalées)
                    for (Reservation r : encoreNonAssignees) {
                        r.setDecalee(true);
                        reservationsEnAttente.add(r);
                    }
                    break;
                }

                // Un véhicule revient dans la fenêtre → on retente avec l'heure ajustée
                heureDepartEffective = plusProchaineDisponibilite;
                nonAssigneesGroupe = encoreNonAssignees;
            }

            // CRÉER UN SEUL TRAJET PAR VÉHICULE avec toutes les fractions du groupe
            creerTrajetsPourVol(heureDepart, assignationsPassageAgregees, vehicules, vitesseMoyenne, vehiculeHeureRetour, trajets, heureDepart);
        }

        // ÉTAPE 4 : Les réservations encore en attente après le DERNIER groupe
        for (Reservation r : reservationsEnAttente) {
            nonAssignees.add(r);
        }

        Map<String, Object> resultat = new HashMap<>();
        resultat.put("trajets", trajets);
        resultat.put("nonAssignees", nonAssignees);
        return resultat;
    }

    private Map<Integer, Integer> initialiserPlacesRestantes(List<Vehicule> vehicules, Map<Integer, String> vehiculeHeureRetour, String heureVol) {
        Map<Integer, Integer> placesRestantes = new HashMap<>();
        for (Vehicule v : vehicules) {
            String heureRetourV = vehiculeHeureRetour.get(v.getId());
            boolean disponible = (heureRetourV == null || heureRetourV.compareTo(heureVol) <= 0);
            if (disponible) {
                placesRestantes.put(v.getId(), v.getNbrPlace());
            }
        }
        return placesRestantes;
    }

    /**
     * Retourne les vehicules disponibles tries par capacite totale decroissante.
     * En cas d'egalite de capacite, on priorise le plus de places restantes puis l'id.
     */
    private List<Integer> trierVehiculesDisponiblesParCapaciteDesc(List<Vehicule> vehicules, Map<Integer, Integer> placesRestantes) {
        List<Vehicule> vehiculesDisponibles = new ArrayList<>();
        for (Vehicule v : vehicules) {
            Integer places = placesRestantes.get(v.getId());
            if (places != null && places > 0) {
                vehiculesDisponibles.add(v);
            }
        }

        vehiculesDisponibles.sort((v1, v2) -> {
            int cmpCapacite = Integer.compare(v2.getNbrPlace(), v1.getNbrPlace());
            if (cmpCapacite != 0) return cmpCapacite;

            int cmpPlacesRestantes = Integer.compare(
                    placesRestantes.get(v2.getId()),
                    placesRestantes.get(v1.getId())
            );
            if (cmpPlacesRestantes != 0) return cmpPlacesRestantes;

            return Integer.compare(v1.getId(), v2.getId());
        });

        List<Integer> ids = new ArrayList<>();
        for (Vehicule v : vehiculesDisponibles) {
            ids.add(v.getId());
        }
        return ids;
    }

private void creerTrajetsPourVol(String heureVol, Map<Integer, List<ReservationAffectee>> assignationsVol, List<Vehicule> vehicules, double vitesseMoyenne, Map<Integer, String> vehiculeHeureRetour, List<Map<String, Object>> trajets, String groupeHeure) {
        for (Map.Entry<Integer, List<ReservationAffectee>> assignation : assignationsVol.entrySet()) {
            int vehiculeId = assignation.getKey();
            List<ReservationAffectee> fractionsAssignees = assignation.getValue();

            // Extraire les réservations de base pour le calcul de distance
            List<Reservation> reservationsForDistance = new ArrayList<>();
            Map<Integer, Integer> qteParReservation = new HashMap<>();
            List<Map<String, Object>> detailsFractions = new ArrayList<>();  // Pour JSP

            for (ReservationAffectee fraction : fractionsAssignees) {
                Reservation res = fraction.getReservation();
                reservationsForDistance.add(res);
                int idRes = res.getId();
                int currentQte = qteParReservation.getOrDefault(idRes, 0);
                qteParReservation.put(idRes, currentQte + fraction.getNbPassagerAffecte());

                // Créer un objet simple pour le JSP avec les infos de la fraction
                Map<String, Object> detailFraction = new LinkedHashMap<>();
                detailFraction.put("id", idRes);
                detailFraction.put("idClient", res.getIdClient());
                detailFraction.put("nomLieu", res.getNomLieu());
                detailFraction.put("dateArrivee", res.getDateArrivee());
                detailFraction.put("decalee", res.isDecalee());
                detailFraction.put("nbPassagerAffecte", fraction.getNbPassagerAffecte());
                detailFraction.put("nbPassagerOriginal", res.getNbPassager());
                detailsFractions.add(detailFraction);
            }

            Vehicule v = trouverVehiculeParId(vehicules, vehiculeId);
            Map<String, Object> infosTrajet = calculerInfosTrajet(reservationsForDistance);

            double distanceTotale = (Double) infosTrajet.get("distanceTotale");
            List<String> ordreTrajet = (List<String>) infosTrajet.get("ordreTrajet");
            String heureRetour = calculerHeureRetour(heureVol, distanceTotale, vitesseMoyenne);

            vehiculeHeureRetour.put(vehiculeId, heureRetour);

            Map<String, Object> trajet = new LinkedHashMap<>();
            trajet.put("vehicule", v);
            trajet.put("detailsFractions", detailsFractions);  // Pour JSP - liste simple d'objets Map
            trajet.put("qteParReservation", qteParReservation);  // Pour affichage en JSP
            trajet.put("distanceTotale", distanceTotale);
            trajet.put("ordreTrajet", ordreTrajet);
            trajet.put("heureDepart", heureVol);
            trajet.put("heureRetour", heureRetour);
            trajet.put("groupeHeure", groupeHeure);
            trajets.add(trajet);
        }
    }

    private Map<String, Object> calculerInfosTrajet(List<Reservation> reservationsAssignees) {
        Map<String, Object> infosTrajet = new HashMap<>();
        infosTrajet.put("distanceTotale", 0.0);
        infosTrajet.put("ordreTrajet", new ArrayList<String>());

        try {
            Map<String, Object> greedyResult = calculerDistanceGreedy(reservationsAssignees);
            infosTrajet.put("distanceTotale", greedyResult.get("distanceTotale"));
            infosTrajet.put("ordreTrajet", greedyResult.get("ordreTrajet"));
        } catch (Exception e) {
            System.err.println("[PLANNING] Erreur calcul distance: " + e.getMessage());
            e.printStackTrace();
        }

        return infosTrajet;
    }

    private String calculerHeureRetour(String heureDepart, double distanceTotale, double vitesseMoyenne) {
        long dureeMs = (long) ((distanceTotale / vitesseMoyenne) * 3600 * 1000);
        return new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
            .format(new java.util.Date(java.sql.Timestamp.valueOf(heureDepart).getTime() + dureeMs));
    }

    /**
     * Cherche un véhicule déjà utilisé dans ce vol avec assez de places restantes.
     */
    private Integer chercherVehiculeDejaUtilise(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Integer vid : assignationsVol.keySet()) {
            Integer places = placesRestantes.get(vid);
            if (places != null && places >= nbPassagers) {
                Vehicule v = trouverVehiculeParId(vehicules, vid);
                if (v != null) candidats.add(v);
            }
        }
        return choisirMeilleurVehicule(candidats, placesRestantes, trajetsParVehicule);
    }

    /**
     * Cherche un nouveau véhicule pas encore utilisé dans ce vol avec assez de places.
     */
    private Integer chercherNouveauVehicule(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Map.Entry<Integer, Integer> entry : placesRestantes.entrySet()) {
            int vid = entry.getKey();
            int places = entry.getValue();
            // Pas encore utilisé dans ce vol ET assez de places
            if (!assignationsVol.containsKey(vid) && places >= nbPassagers) {
                Vehicule v = trouverVehiculeParId(vehicules, vid);
                if (v != null) candidats.add(v);
            }
        }
        return choisirMeilleurVehicule(candidats, placesRestantes, trajetsParVehicule);
    }

    /**
     * Parmi les candidats, choisit le meilleur véhicule.
     * Critères (dans l'ordre) :
     *   1. Moins de places restantes (plus petit qui convient) — EXISTANT
     *   2. Moins de trajets effectués dans la journée — NOUVEAU
     *   3. Priorité carburant : D > ES > H — ÉLARGI
     */
    private Integer choisirMeilleurVehicule(List<Vehicule> candidats, Map<Integer, Integer> placesRestantes, Map<Integer, Integer> trajetsParVehicule) {
        if (candidats.isEmpty()) return null;

        // Tri multi-critères (bubble sort)
        for (int i = 0; i < candidats.size() - 1; i++) {
            for (int j = 0; j < candidats.size() - i - 1; j++) {
                Vehicule v1 = candidats.get(j);
                Vehicule v2 = candidats.get(j + 1);
                int p1 = placesRestantes.get(v1.getId());
                int p2 = placesRestantes.get(v2.getId());

                boolean swap = false;
                if (p1 > p2) {
                    // 1. Moins de places restantes en premier
                    swap = true;
                } else if (p1 == p2) {
                    int t1 = trajetsParVehicule.getOrDefault(v1.getId(), 0);
                    int t2 = trajetsParVehicule.getOrDefault(v2.getId(), 0);
                    if (t1 > t2) {
                        // 2. Moins de trajets en premier
                        swap = true;
                    } else if (t1 == t2) {
                        // 3. Priorité carburant : D > ES > H
                        if (prioriteCarburant(v1.getTypeCarburant()) < prioriteCarburant(v2.getTypeCarburant())) {
                            swap = true;
                        }
                    }
                }

                if (swap) {
                    candidats.set(j, v2);
                    candidats.set(j + 1, v1);
                }
            }
        }

        return candidats.get(0).getId();
    }

    private int prioriteCarburant(String typeCarburant) {
        if ("D".equals(typeCarburant)) return 3;
        if ("ES".equals(typeCarburant)) return 2;
        if ("H".equals(typeCarburant)) return 1;
        return 0;
    }

    /** Trouve un véhicule dans la liste par son id */
    private Vehicule trouverVehiculeParId(List<Vehicule> vehicules, int id) {
        for (Vehicule v : vehicules) {
            if (v.getId() == id) return v;
        }
        return null;
    }

    /** Tri par nbPassager décroissant (bubble sort) */
    private void trierParNbPassagerDesc(List<Reservation> reservations) {
        for (int i = 0; i < reservations.size() - 1; i++) {
            for (int j = 0; j < reservations.size() - i - 1; j++) {
                if (reservations.get(j).getNbPassager() < reservations.get(j + 1).getNbPassager()) {
                    Reservation tmp = reservations.get(j);
                    reservations.set(j, reservations.get(j + 1));
                    reservations.set(j + 1, tmp);
                }
            }
        }
    }

    /** Ajoute des minutes à un timestamp au format "yyyy-MM-dd HH:mm:ss" */
    private String ajouterMinutes(String timestamp, int minutes) {
        long ms = java.sql.Timestamp.valueOf(timestamp).getTime();
        ms += (long) minutes * 60 * 1000;
        return new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
            .format(new java.util.Date(ms));
    }
}

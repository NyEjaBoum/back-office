package dao;

import model.Lieu;
import model.Reservation;
import model.Vehicule;
import java.util.*;

public class PlanningDao {

    private DistanceDao distanceDao = new DistanceDao();
    private LieuDao lieuDao = new LieuDao();

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
     * Pour chaque vol (même date+heure exacte) :
     *   Les réservations sont déjà triées par nbPassager DÉCROISSANT (fait dans regrouperParVol)
     *
     *   Pour chaque réservation du vol :
     *     1. Chercher un véhicule déjà utilisé dans ce vol avec assez de places restantes
     *     2. Sinon, chercher un nouveau véhicule disponible (pas encore utilisé ce vol)
     *     3. Si trouvé : assigner la réservation à ce véhicule
     *     4. Si non trouvé : réservation non assignée
     *
     *   Règle véhicule : places restantes >= nbPassagers de la réservation
     *   Choix : plus petit véhicule qui convient, priorité Diesel
     */
    public Map<String, Object> planifier(
            Map<String, List<Reservation>> vols,
            List<Vehicule> vehicules,
            double vitesseMoyenne) {

        List<Map<String, Object>> trajets = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();

        // vehiculeId -> heure de retour (pour savoir si le véhicule est libre pour un prochain vol)
        Map<Integer, String> vehiculeHeureRetour = new HashMap<>();

        for (Map.Entry<String, List<Reservation>> entry : vols.entrySet()) {
            String heureVol = entry.getKey();
            List<Reservation> reservationsVol = entry.getValue();
            // Réservations déjà triées par nbPassager décroissant (fait dans regrouperParVol)

            // Pour ce vol : vehiculeId -> places restantes
            Map<Integer, Integer> placesRestantes = new HashMap<>();
            // Pour ce vol : vehiculeId -> liste des réservations assignées
            Map<Integer, List<Reservation>> assignationsVol = new LinkedHashMap<>();

            // Initialiser les places restantes pour les véhicules DISPONIBLES à cette heure
            for (Vehicule v : vehicules) {
                String heureRetourV = vehiculeHeureRetour.get(v.getId());
                boolean disponible = (heureRetourV == null || heureRetourV.compareTo(heureVol) <= 0);
                if (disponible) {
                    placesRestantes.put(v.getId(), v.getNbrPlace());
                }
            }

            // Traiter chaque réservation du vol (du plus grand au plus petit groupe)
            for (Reservation r : reservationsVol) {
                int nbPassagers = r.getNbPassager();
                Integer vehiculeChoisiId = null;

                // Étape 1 : chercher un véhicule DÉJÀ utilisé dans ce vol avec assez de place
                // (pour regrouper au maximum dans les véhicules déjà ouverts)
                vehiculeChoisiId = chercherVehiculeDejaUtilise(assignationsVol, placesRestantes, nbPassagers, vehicules);

                // Étape 2 : si aucun véhicule déjà utilisé ne convient, prendre un nouveau véhicule
                if (vehiculeChoisiId == null) {
                    vehiculeChoisiId = chercherNouveauVehicule(assignationsVol, placesRestantes, nbPassagers, vehicules);
                }

                if (vehiculeChoisiId != null) {
                    // Assigner
                    if (!assignationsVol.containsKey(vehiculeChoisiId)) {
                        assignationsVol.put(vehiculeChoisiId, new ArrayList<>());
                    }
                    assignationsVol.get(vehiculeChoisiId).add(r);
                    placesRestantes.put(vehiculeChoisiId, placesRestantes.get(vehiculeChoisiId) - nbPassagers);
                } else {
                    nonAssignees.add(r);
                }
            }

            // Créer les trajets pour ce vol
            for (Map.Entry<Integer, List<Reservation>> assignation : assignationsVol.entrySet()) {
                int vehiculeId = assignation.getKey();
                List<Reservation> reservationsAssignees = assignation.getValue();

                Vehicule v = trouverVehiculeParId(vehicules, vehiculeId);

                double distanceTotale = 0.0;
                List<String> ordreTrajet = new ArrayList<>();
                try {
                    Map<String, Object> greedyResult = calculerDistanceGreedy(reservationsAssignees);
                    distanceTotale = (Double) greedyResult.get("distanceTotale");
                    ordreTrajet = (List<String>) greedyResult.get("ordreTrajet");
                } catch (Exception e) {
                    System.err.println("[PLANNING] Erreur calcul distance: " + e.getMessage());
                    e.printStackTrace();
                    distanceTotale = 0.0;
                }

                long dureeMs = (long) ((distanceTotale / vitesseMoyenne) * 3600 * 1000);
                String heureRetour = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
                    .format(new java.util.Date(java.sql.Timestamp.valueOf(heureVol).getTime() + dureeMs));

                // Mettre à jour l'heure de retour du véhicule
                vehiculeHeureRetour.put(vehiculeId, heureRetour);

                Map<String, Object> trajet = new LinkedHashMap<>();
                trajet.put("vehicule", v);
                trajet.put("reservations", reservationsAssignees);
                trajet.put("distanceTotale", distanceTotale);
                trajet.put("ordreTrajet", ordreTrajet);
                trajet.put("heureDepart", heureVol);
                trajet.put("heureRetour", heureRetour);
                trajets.add(trajet);
            }
        }

        Map<String, Object> resultat = new HashMap<>();
        resultat.put("trajets", trajets);
        resultat.put("nonAssignees", nonAssignees);
        return resultat;
    }

    /**
     * Cherche un véhicule déjà utilisé dans ce vol avec assez de places restantes.
     * Prend le plus petit véhicule qui convient (priorité Diesel).
     */
    private Integer chercherVehiculeDejaUtilise(
            Map<Integer, List<Reservation>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Integer vid : assignationsVol.keySet()) {
            Integer places = placesRestantes.get(vid);
            if (places != null && places >= nbPassagers) {
                Vehicule v = trouverVehiculeParId(vehicules, vid);
                if (v != null) candidats.add(v);
            }
        }
        return choisirMeilleurVehicule(candidats, placesRestantes);
    }

    /**
     * Cherche un nouveau véhicule pas encore utilisé dans ce vol avec assez de places.
     * Prend le plus petit véhicule qui convient (priorité Diesel).
     */
    private Integer chercherNouveauVehicule(
            Map<Integer, List<Reservation>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules) {

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
        return choisirMeilleurVehicule(candidats, placesRestantes);
    }

    /**
     * Parmi les candidats, choisit le véhicule avec le moins de places restantes
     * (le plus petit qui convient), priorité Diesel en cas d'égalité.
     * Retourne l'id du véhicule choisi, ou null si aucun candidat.
     */
    private Integer choisirMeilleurVehicule(List<Vehicule> candidats, Map<Integer, Integer> placesRestantes) {
        if (candidats.isEmpty()) return null;

        // Tri par places restantes croissantes (bubble sort)
        for (int i = 0; i < candidats.size() - 1; i++) {
            for (int j = 0; j < candidats.size() - i - 1; j++) {
                int p1 = placesRestantes.get(candidats.get(j).getId());
                int p2 = placesRestantes.get(candidats.get(j + 1).getId());
                if (p1 > p2) {
                    Vehicule tmp = candidats.get(j);
                    candidats.set(j, candidats.get(j + 1));
                    candidats.set(j + 1, tmp);
                }
            }
        }

        // Parmi ceux avec le même nombre de places restantes, priorité Diesel
        int minPlaces = placesRestantes.get(candidats.get(0).getId());
        for (Vehicule v : candidats) {
            if (placesRestantes.get(v.getId()) == minPlaces && "D".equals(v.getTypeCarburant())) {
                return v.getId();
            }
        }
        return candidats.get(0).getId();
    }

    /** Trouve un véhicule dans la liste par son id */
    private Vehicule trouverVehiculeParId(List<Vehicule> vehicules, int id) {
        for (Vehicule v : vehicules) {
            if (v.getId() == id) return v;
        }
        return null;
    }
}
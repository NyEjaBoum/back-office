package dao;

import model.Reservation;
import model.Vehicule;
import java.util.*;

public class PlanningDao {

    /**
     * Calcule la distance totale (greedy) pour un groupe de réservations
     * Utilise DistanceDao pour récupérer la distance entre deux lieux
     */
    public double calculerDistanceGreedy(List<Reservation> groupe) {
        DistanceDao distanceDao = new DistanceDao();
        List<Integer> lieux = extraireLieux(groupe);
        if (lieux.size() <= 1) return 0.0;

        double total = 0.0;
        List<Integer> nonVisites = new ArrayList<>(lieux);
        Integer current = nonVisites.get(0);
        nonVisites.remove(current);

        while (!nonVisites.isEmpty()) {
            Integer next = null;
            double minDist = Double.MAX_VALUE;
            for (Integer l : nonVisites) {
                double dist;
                try {
                    dist = distanceDao.getDistance(current, l);
                } catch (Exception e) {
                    dist = Double.MAX_VALUE;
                }
                if (dist >= 0 && dist < minDist) {
                    minDist = dist;
                    next = l;
                }
            }
            if (next == null) break;
            total += minDist;
            current = next;
            nonVisites.remove(next);
        }
        return total;
    }

    /** Sous-fonction pour extraire les lieux uniques d'un groupe */
    private List<Integer> extraireLieux(List<Reservation> groupe) {
        List<Integer> lieux = new ArrayList<>();
        for (Reservation r : groupe) {
            if (!lieux.contains(r.getIdLieu())) {
                lieux.add(r.getIdLieu());
            }
        }
        return lieux;
    }

    /**
     * Planifie les groupes de réservations avec assignation des véhicules
     */
    public Map<Vehicule, Map<String, Object>> planifier(List<List<Reservation>> groupes, List<Vehicule> vehicules, VehiculeDao vehiculeDao) {
        Map<Vehicule, Map<String, Object>> planning = new LinkedHashMap<>();
        Set<Integer> vehiculesOccupes = new HashSet<>();

        for (List<Reservation> groupe : groupes) {
            int nbPassagersGroupe = 0;
            for (Reservation r : groupe) nbPassagersGroupe += r.getNbPassager();

            List<Vehicule> candidats = vehiculeDao.filtrerVehiculesCandidats(vehicules, nbPassagersGroupe, vehiculesOccupes);
            Vehicule choisi = vehiculeDao.choisirVehicule(candidats);

            if (choisi != null) {
                vehiculesOccupes.add(choisi.getId());
                double distanceTotale = calculerDistanceGreedy(groupe);
                String heureDepart = groupe.get(0).getDateArrivee();
                double vitesseMoyenne = 40; // à récupérer depuis parametre si besoin
                long dureeMs = (long) ((distanceTotale / vitesseMoyenne) * 3600 * 1000);
                String heureRetour = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
                    .format(new java.util.Date(java.sql.Timestamp.valueOf(heureDepart).getTime() + dureeMs));

                Map<String, Object> info = new HashMap<>();
                info.put("reservations", groupe);
                info.put("distanceTotale", distanceTotale);
                info.put("heureDepart", heureDepart);
                info.put("heureRetour", heureRetour);

                planning.put(choisi, info);
            }
        }
        return planning;
    }

    public List<String> afficherEtapesDistance(List<Reservation> groupe) {
        DistanceDao distanceDao = new DistanceDao();
        List<Integer> lieux = extraireLieux(groupe);
        List<String> etapes = new ArrayList<>();
        if (lieux.size() <= 1) return etapes;

        List<Integer> nonVisites = new ArrayList<>(lieux);
        Integer current = nonVisites.get(0);
        nonVisites.remove(current);

        while (!nonVisites.isEmpty()) {
            Integer next = null;
            double minDist = Double.MAX_VALUE;
            for (Integer l : nonVisites) {
                double dist;
                try {
                    dist = distanceDao.getDistance(current, l);
                } catch (Exception e) {
                    dist = Double.MAX_VALUE;
                }
                if (dist >= 0 && dist < minDist) {
                    minDist = dist;
                    next = l;
                }
            }
            if (next == null) break;
            etapes.add("De " + current + " à " + next + " : " + minDist + " km");
            current = next;
            nonVisites.remove(next);
        }
        return etapes;
    }
}
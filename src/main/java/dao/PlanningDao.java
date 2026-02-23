package dao;

import model.Lieu;
import model.Reservation;
import model.Vehicule;
import java.util.*;

public class PlanningDao {

    private DistanceDao distanceDao = new DistanceDao();
    private LieuDao lieuDao = new LieuDao();

    /**
     * Retourne l'id du lieu "Aeroport" (code = AERO)
     */
    private int getIdAeroport() throws Exception {
        Lieu aeroport = lieuDao.findByCode("AERO");
        if (aeroport == null) throw new Exception("Lieu 'AERO' introuvable en base");
        return aeroport.getId();
    }

    /**
     * Calcule la distance totale (greedy) pour un groupe de reservations.
     * Trajet : Aeroport -> lieux (greedy nearest neighbor) -> Aeroport
     */
    public double calculerDistanceGreedy(List<Reservation> groupe) throws Exception {
        int idAeroport = getIdAeroport();
        List<Integer> lieux = extraireLieux(groupe);
        if (lieux.isEmpty()) return 0.0;

        double total = 0.0;
        List<Integer> nonVisites = new ArrayList<>(lieux);

        // Aeroport -> premier lieu le plus proche
        Integer current = null;
        double minDist = Double.MAX_VALUE;
        for (Integer l : nonVisites) {
            double dist = distanceDao.getDistance(idAeroport, l);
            if (dist >= 0 && dist < minDist) {
                minDist = dist;
                current = l;
            }
        }
        if (current == null) return 0.0;
        total += minDist;
        nonVisites.remove(current);

        // Greedy : lieu courant -> lieu le plus proche non visite
        while (!nonVisites.isEmpty()) {
            Integer next = null;
            minDist = Double.MAX_VALUE;
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

        // Dernier lieu -> Aeroport (retour)
        double retour = distanceDao.getDistance(current, idAeroport);
        if (retour >= 0) {
            total += retour;
        }

        return total;
    }

    /** Extrait les lieux uniques d'un groupe */
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
     * Retourne l'heure d'arrivee la plus tardive du groupe
     */
    private String getHeureDepartGroupe(List<Reservation> groupe) {
        String max = groupe.get(0).getDateArrivee();
        for (Reservation r : groupe) {
            if (r.getDateArrivee().compareTo(max) > 0) {
                max = r.getDateArrivee();
            }
        }
        return max;
    }

    /**
     * Planifie les groupes de reservations avec assignation des vehicules.
     * - heureDepart = heure d'arrivee la plus tardive du groupe
     * - heureRetour = heureDepart + (distanceTotale / vitesseMoyenne)
     */
    public Map<Vehicule, Map<String, Object>> planifier(
            List<List<Reservation>> groupes,
            List<Vehicule> vehicules,
            VehiculeDao vehiculeDao,
            double vitesseMoyenne) {

        Map<Vehicule, Map<String, Object>> planning = new LinkedHashMap<>();
        Set<Integer> vehiculesOccupes = new HashSet<>();

        for (List<Reservation> groupe : groupes) {
            int nbPassagersGroupe = 0;
            for (Reservation r : groupe) nbPassagersGroupe += r.getNbPassager();

            List<Vehicule> candidats = vehiculeDao.filtrerVehiculesCandidats(vehicules, nbPassagersGroupe, vehiculesOccupes);
            Vehicule choisi = vehiculeDao.choisirVehicule(candidats);

            if (choisi != null) {
                vehiculesOccupes.add(choisi.getId());

                double distanceTotale;
                try {
                    distanceTotale = calculerDistanceGreedy(groupe);
                } catch (Exception e) {
                    distanceTotale = 0.0;
                }

                // Depart = heure d'arrivee la plus tardive du groupe
                String heureDepart = getHeureDepartGroupe(groupe);

                // Retour = depart + (distanceTotale / vitesseMoyenne) en heures
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
}

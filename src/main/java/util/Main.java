package util;

import dao.ReservationDao;
import dao.VehiculeDao;
import dao.PlanningDao;
import dao.DistanceDao;
import model.Reservation;
import model.Vehicule;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;

public class Main {
    public static void main(String[] args) {
        try {
            String date = "2026-03-01"; // Mets ici la date que tu veux tester

            ReservationDao reservationDao = new ReservationDao();
            VehiculeDao vehiculeDao = new VehiculeDao();
            PlanningDao planningDao = new PlanningDao();

            // 1. Récupérer les réservations du jour depuis la base
            List<Reservation> reservations = reservationDao.findByDate(date);

            // 2. Récupérer tous les véhicules depuis la base
            List<Vehicule> vehicules = vehiculeDao.findAll();

            // 3. Paramètres (à récupérer en base si tu veux)
            int tempsAttente = 30;
            double vitesseMoyenne = 40;

            // 4. Regrouper les réservations
            List<List<Reservation>> groupes = reservationDao.regrouperReservations(reservations, tempsAttente);

            // 5. Planifier
            Map<Vehicule, Map<String, Object>> planning = planningDao.planifier(groupes, vehicules, vehiculeDao);

            // 6. Affichage
            int i = 1;
            for (Map.Entry<Vehicule, Map<String, Object>> entry : planning.entrySet()) {
                Map<String, Object> info = entry.getValue();
                List<Reservation> groupe = (List<Reservation>) info.get("reservations");
                double distanceTotale = (double) info.get("distanceTotale");
                String heureDepart = (String) info.get("heureDepart");
                String heureRetour = (String) info.get("heureRetour");

                System.out.println("Trajet " + i + " : " + entry.getKey());
                for (Reservation r : groupe) {
                    System.out.println("  - " + r);
                }
                // Affichage des étapes de distance
                List<String> etapes = planningDao.afficherEtapesDistance(groupe);
                for (String etape : etapes) {
                    System.out.println("    " + etape);
                }
                System.out.println("  Distance totale : " + distanceTotale + " km");
                System.out.println("  Heure départ : " + heureDepart);
                System.out.println("  Heure retour : " + heureRetour);
                i++;
            }

            // 7. Afficher les réservations non assignées
            // On récupère tous les IDs de réservations assignées
            Set<Integer> reservationsAssignees = new HashSet<>();
            for (Map.Entry<Vehicule, Map<String, Object>> entry : planning.entrySet()) {
                List<Reservation> groupe = (List<Reservation>) entry.getValue().get("reservations");
                for (Reservation r : groupe) {
                    reservationsAssignees.add(r.getId());
                }
            }
            System.out.println("\nRéservations non assignées :");
            for (Reservation r : reservations) {
                if (!reservationsAssignees.contains(r.getId())) {
                    System.out.println("  - " + r);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
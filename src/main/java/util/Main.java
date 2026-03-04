package util;

import dao.ReservationDao;
import dao.VehiculeDao;
import dao.PlanningDao;
import dao.ParametreDao;
import model.Reservation;
import model.Vehicule;
import java.util.*;

public class Main {
    public static void main(String[] args) {
        try {
            String date = "2026-03-01";

            ReservationDao reservationDao = new ReservationDao();
            VehiculeDao vehiculeDao = new VehiculeDao();
            PlanningDao planningDao = new PlanningDao();
            ParametreDao parametreDao = new ParametreDao();

            // 1. Réservations du jour
            List<Reservation> reservations = reservationDao.findByDate(date);

            // 2. Véhicules
            List<Vehicule> vehicules = vehiculeDao.findAll();

            // 3. Paramètres
            double vitesseMoyenne = parametreDao.getVitesseMoyenne();
            int tempsAttente = parametreDao.getTempsAttente();

            // Regrouper par vol avec temps d'attente
            Map<String, List<Reservation>> vols = reservationDao.regrouperParVol(reservations, tempsAttente);

            // 5. Planifier
            Map<String, Object> resultat = planningDao.planifier(vols, vehicules, vitesseMoyenne);

            List<Map<String, Object>> trajets = (List<Map<String, Object>>) resultat.get("trajets");
            List<Reservation> nonAssignees = (List<Reservation>) resultat.get("nonAssignees");

            // 6. Affichage des trajets
            int i = 1;
            for (Map<String, Object> trajet : trajets) {
                Vehicule v = (Vehicule) trajet.get("vehicule");
                List<Reservation> resa = (List<Reservation>) trajet.get("reservations");
                double dist = (double) trajet.get("distanceTotale");
                String depart = (String) trajet.get("heureDepart");
                String retour = (String) trajet.get("heureRetour");

                int totalPassagers = 0;
                for (Reservation r : resa) totalPassagers += r.getNbPassager();

                System.out.println("Trajet " + i + " : " + v.getReference()
                    + " (" + v.getNbrPlace() + " places) | " + totalPassagers + " passagers");
                for (Reservation r : resa) {
                    System.out.println("  - [" + r.getNbPassager() + " pass.] " + r.getNomLieu() + " | " + r);
                }
                System.out.println("  Distance : " + dist + " km");
                System.out.println("  Départ : " + depart + " | Retour : " + retour);
                System.out.println();
                i++;
            }

            // 7. Réservations non assignées
            System.out.println("=== Réservations non assignées ===");
            if (nonAssignees.isEmpty()) {
                System.out.println("  Aucune !");
            } else {
                for (Reservation r : nonAssignees) {
                    System.out.println("  - [" + r.getNbPassager() + " pass.] " + r);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
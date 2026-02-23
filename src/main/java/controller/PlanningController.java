package controller;

import annotation.controllerAnnotation;
import annotation.Get;
import annotation.Post;
import annotation.requestParam;
import model.ModelView;
import dao.ReservationDao;
import dao.VehiculeDao;
import dao.ParametreDao;
import dao.PlanningDao;
import model.Reservation;
import model.Vehicule;
import java.util.*;

@controllerAnnotation
public class PlanningController {

    @Get("/planning")
    public ModelView showDateForm() {
        return new ModelView("/WEB-INF/views/planningDateForm.jsp");
    }

    @Post("/planning")
    public ModelView handleDateForm(@requestParam("date") String date) {
        ModelView mv = new ModelView("/WEB-INF/views/planningResult.jsp");
        mv.addData("date", date);

        try {
            ReservationDao reservationDao = new ReservationDao();
            VehiculeDao vehiculeDao = new VehiculeDao();
            PlanningDao planningDao = new PlanningDao();

            // 1. Récupérer les réservations du jour
            List<Reservation> reservationsJour = reservationDao.findByDate(date);

            // 2. Récupérer tous les véhicules
            List<Vehicule> vehicules = vehiculeDao.findAll();

            // 3. Récupérer les paramètres (exemple en dur, sinon ParametreDao)
            ParametreDao parametreDao = new ParametreDao();
            int tempsAttente = parametreDao.getTempsAttente();
            double vitesseMoyenne = parametreDao.getVitesseMoyenne();

            // 4. Regrouper les réservations
            List<List<Reservation>> groupes = reservationDao.regrouperReservations(reservationsJour, tempsAttente);

            // 5. Planifier
            Map<Vehicule, Map<String, Object>> planning = planningDao.planifier(groupes, vehicules, vehiculeDao, vitesseMoyenne);

            // 6. Construire les deux tableaux
            List<Map<String, Object>> vehiculesPlanifies = new ArrayList<>();
            Set<Integer> reservationsAssignees = new HashSet<>();
            for (Map.Entry<Vehicule, Map<String, Object>> entry : planning.entrySet()) {
                Map<String, Object> info = entry.getValue();
                List<Reservation> groupe = (List<Reservation>) info.get("reservations");
                for (Reservation r : groupe) {
                    reservationsAssignees.add(r.getId());
                }
                Map<String, Object> ligne = new HashMap<>();
                ligne.put("vehicule", entry.getKey());
                ligne.put("reservations", groupe);
                ligne.put("heureDepart", info.get("heureDepart"));
                ligne.put("heureRetour", info.get("heureRetour"));
                vehiculesPlanifies.add(ligne);
            }

            // 7. Réservations non assignées
            List<Reservation> nonAssignees = new ArrayList<>();
            for (Reservation r : reservationsJour) {
                if (!reservationsAssignees.contains(r.getId())) {
                    nonAssignees.add(r);
                }
            }

            mv.addData("vehiculesPlanifies", vehiculesPlanifies);
            mv.addData("reservationsNonAssignees", nonAssignees);

        } catch (Exception e) {
            mv.addData("error", "Erreur lors de la planification : " + e.getMessage());
        }

        return mv;
    }
}
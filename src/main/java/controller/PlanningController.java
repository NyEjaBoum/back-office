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
            ParametreDao parametreDao = new ParametreDao();

            // 1. Réservations du jour
            List<Reservation> reservationsJour = reservationDao.findByDate(date);

            // 2. Véhicules
            List<Vehicule> vehicules = vehiculeDao.findAll();

            // 3. Paramètres
            double vitesseMoyenne = parametreDao.getVitesseMoyenne();
            int tempsAttente = parametreDao.getTempsAttente();

            // 4. Regrouper par vol avec temps d'attente
            Map<String, List<Reservation>> vols = reservationDao.regrouperParVol(reservationsJour, tempsAttente);

            // 5. Planifier
            Map<String, Object> resultat = planningDao.planifier(vols, vehicules, vitesseMoyenne);

            // 6. Extraire les résultats
            List<Map<String, Object>> trajets = (List<Map<String, Object>>) resultat.get("trajets");
            List<Reservation> nonAssignees = (List<Reservation>) resultat.get("nonAssignees");

            mv.addData("vehiculesPlanifies", trajets);
            mv.addData("reservationsNonAssignees", nonAssignees);

        } catch (Exception e) {
            mv.addData("error", "Erreur lors de la planification : " + e.getMessage());
            e.printStackTrace();
        }

        return mv;
    }
}
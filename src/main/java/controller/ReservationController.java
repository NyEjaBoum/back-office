package controller;

import annotation.controllerAnnotation;
import annotation.Get;
import annotation.Post;
import annotation.Json;
import annotation.requestParam;
import model.ModelView;
import model.Reservation;
import model.Lieu;
import dao.ReservationDao;
import dao.LieuDao;
import dao.TokenDao;
import model.Token;
import jakarta.servlet.http.HttpServletRequest;

import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

@controllerAnnotation
public class ReservationController {

    // Afficher le formulaire d'ajout de réservation
    @Get("/reservations/add")
    public ModelView showAddForm() {
        ModelView mv = new ModelView("/WEB-INF/views/reservationForm.jsp");

        try {
            LieuDao lieuDao = new LieuDao();
            List<Lieu> lieux = lieuDao.findAll();
            System.out.println("Nombre de lieux trouvés: " + lieux.size());
            mv.addData("lieux", lieux);
        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des lieux: " + e.getMessage());
            mv.addData("lieux", new ArrayList<Lieu>());
        }

        return mv;
    }

    // Traiter l'ajout d'une réservation
    @Post("/reservations/add")
    public ModelView addReservation(
            @requestParam("clientId") String clientId,
            @requestParam("nbPassager") int nbPassager,
            @requestParam("idLieu") int idLieu,
            @requestParam("dateHeureArrivee") String dateHeureArrivee) {

        ModelView mv = new ModelView("/WEB-INF/views/reservationForm.jsp");

        try {
            // Validation du client_id (4 chiffres)
            if (clientId == null || !clientId.matches("\\d{4}")) {
                throw new IllegalArgumentException("L'ID client doit contenir exactement 4 chiffres");
            }

            // Validation du nombre de passagers
            if (nbPassager <= 0) {
                throw new IllegalArgumentException("Le nombre de passagers doit être supérieur à 0");
            }

            // Conversion de la date
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
            java.util.Date parsedDate = sdf.parse(dateHeureArrivee);

            // Créer la réservation
            Reservation reservation = new Reservation();
            reservation.setIdClient(clientId);
            reservation.setNbPassager(nbPassager);
            reservation.setIdLieu(idLieu);
            SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            String dateStr = sdf2.format(parsedDate);
            reservation.setDateArrivee(dateStr);

            // Sauvegarder en base
            ReservationDao reservationDao = new ReservationDao();
            reservationDao.insert(reservation);

            mv.addData("success", "Réservation ajoutée avec succès!");

        } catch (Exception e) {
            mv.addData("error", "Erreur lors de l'ajout de la réservation: " + e.getMessage());
        }

        // Recharger la liste des lieux pour le formulaire
        try {
            LieuDao lieuDao = new LieuDao();
            List<Lieu> lieux = lieuDao.findAll();
            mv.addData("lieux", lieux);
        } catch (Exception e) {
            mv.addData("lieux", new ArrayList<Lieu>());
        }

        return mv;
    }

    // API REST - Liste des réservations (avec infos lieu)
    @Get("/api/reservations")
    @Json
    public Object listReservations(HttpServletRequest request) {
        try {
            String tokenValue = request.getHeader("X-API-TOKEN");
            if (tokenValue == null || tokenValue.isEmpty()) {
                return java.util.Map.of("error", "token manquant");
            }
            TokenDao tokenDao = new TokenDao();
            Token token = tokenDao.findByToken(tokenValue);
            if (token == null) {
                return java.util.Map.of("error", "token invalide");
            }
            if (token.getDateExpiration().before(new java.util.Date())) {
                return java.util.Map.of("error", "token expire");
            }
            ReservationDao reservationDao = new ReservationDao();
            return reservationDao.findAll();
        } catch (Exception e) {
            return java.util.Map.of("error", "Erreur serveur: " + e.getMessage());
        }
    }

    // Afficher la liste des réservations (page Back Office) avec filtres
    @Get("/reservations")
    public ModelView listReservationsView(HttpServletRequest request) {
        ModelView mv = new ModelView("/WEB-INF/views/reservationList.jsp");

        try {
            ReservationDao reservationDao = new ReservationDao();
            String date = request.getParameter("date");
            String tri = request.getParameter("tri");

            List<Reservation> reservations;
            if (date != null && !date.isEmpty()) {
                reservations = reservationDao.findByDate(date);
            } else {
                reservations = reservationDao.findAll();
            }

            // Tri selon le paramètre choisi
            if ("nom".equals(tri)) {
                // Tri alphabétique par nom de lieu
                for (int i = 0; i < reservations.size() - 1; i++) {
                    for (int j = 0; j < reservations.size() - i - 1; j++) {
                        String nom1 = reservations.get(j).getNomLieu() != null ? reservations.get(j).getNomLieu() : "";
                        String nom2 = reservations.get(j + 1).getNomLieu() != null ? reservations.get(j + 1).getNomLieu() : "";
                        if (nom1.compareTo(nom2) > 0) {
                            Reservation tmp = reservations.get(j);
                            reservations.set(j, reservations.get(j + 1));
                            reservations.set(j + 1, tmp);
                        }
                    }
                }
            } else if ("dateAsc".equals(tri)) {
                // Tri par date croissante
                for (int i = 0; i < reservations.size() - 1; i++) {
                    for (int j = 0; j < reservations.size() - i - 1; j++) {
                        String d1 = reservations.get(j).getDateArrivee() != null ? reservations.get(j).getDateArrivee() : "";
                        String d2 = reservations.get(j + 1).getDateArrivee() != null ? reservations.get(j + 1).getDateArrivee() : "";
                        if (d1.compareTo(d2) > 0) {
                            Reservation tmp = reservations.get(j);
                            reservations.set(j, reservations.get(j + 1));
                            reservations.set(j + 1, tmp);
                        }
                    }
                }
            } else if ("passagers".equals(tri)) {
                // Tri par nombre de passagers décroissant
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
            // Par défaut (tri == null ou "dateDesc") : findAll retourne déjà ORDER BY dateArrivee DESC

            mv.addData("reservations", reservations);
            mv.addData("dateFiltre", date);
            mv.addData("triFiltre", tri);
        } catch (Exception e) {
            mv.addData("error", "Erreur lors du chargement des réservations: " + e.getMessage());
            mv.addData("reservations", new ArrayList<Reservation>());
        }

        return mv;
    }
}
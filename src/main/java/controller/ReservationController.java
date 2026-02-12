package controller;

import annotation.controllerAnnotation;
import annotation.Get;
import annotation.Post;
import annotation.Json;
import annotation.requestParam;
import model.ModelView;
import model.Reservation;
import model.Hotel;
import dao.ReservationDao;
import dao.HotelDao;
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
            HotelDao hotelDao = new HotelDao();
            List<Hotel> hotels = hotelDao.findAll();
            System.out.println("Nombre d'hôtels trouvés: " + hotels.size());
            mv.addData("hotels", hotels);
        } catch (Exception e) {
            e.printStackTrace(); // Affiche la stack trace complète
            mv.addData("error", "Erreur lors du chargement des hôtels: " + e.getMessage());
            mv.addData("hotels", new ArrayList<Hotel>());
        }
        
        return mv;
    }

    // Traiter l'ajout d'une réservation
    @Post("/reservations/add")
    public ModelView addReservation(
            @requestParam("clientId") String clientId,
            @requestParam("nbPassager") int nbPassager,
            @requestParam("idHotel") int idHotel,
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
            // Timestamp timestamp = new Timestamp(parsedDate.getTime());
            
            // Créer la réservation
            Reservation reservation = new Reservation();
            reservation.setIdClient(clientId);
            reservation.setNbPassager(nbPassager);
            reservation.setIdHotel(idHotel);
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
        
        // Recharger la liste des hôtels pour le formulaire
        try {
            HotelDao hotelDao = new HotelDao();
            List<Hotel> hotels = hotelDao.findAll();
            mv.addData("hotels", hotels);
        } catch (Exception e) {
            mv.addData("hotels", new ArrayList<Hotel>());
        }
        
        return mv;
    }

    // API REST - Liste des réservations (avec infos hôtel)
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

    // Afficher la liste des réservations (page Back Office)
    @Get("/reservations")
    public ModelView listReservationsView() {
        ModelView mv = new ModelView("/WEB-INF/views/reservationList.jsp");
        
        try {
            ReservationDao reservationDao = new ReservationDao();
            List<Reservation> reservations = reservationDao.findAll();
            mv.addData("reservations", reservations);
        } catch (Exception e) {
            mv.addData("error", "Erreur lors du chargement des réservations: " + e.getMessage());
            mv.addData("reservations", new ArrayList<Reservation>());
        }
        
        return mv;
    }
}

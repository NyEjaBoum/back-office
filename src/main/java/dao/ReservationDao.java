package dao;

import model.Reservation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ReservationDao {

    public void insert(Reservation reservation) throws SQLException {
        String sql = "INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, reservation.getIdClient());
            stmt.setInt(2, reservation.getNbPassager());
            stmt.setInt(3, reservation.getIdLieu());
            Timestamp ts = null;
            if (reservation.getDateArrivee() != null && !reservation.getDateArrivee().isEmpty()) {
                ts = Timestamp.valueOf(reservation.getDateArrivee());
            }
            stmt.setTimestamp(4, ts);
            stmt.executeUpdate();
        }
    }

    public List<Reservation> findAll() throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idLieu, r.dateArrivee, l.libelle AS lieuNom " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idLieu = l.id " +
                     "ORDER BY r.dateArrivee DESC";
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Reservation r = new Reservation();
                r.setId(rs.getInt("id"));
                r.setIdClient(rs.getString("idClient"));
                r.setNbPassager(rs.getInt("nbPassager"));
                r.setIdLieu(rs.getInt("idLieu"));
                Timestamp ts = rs.getTimestamp("dateArrivee");
                r.setDateArrivee(ts != null ? sdf.format(ts) : null);
                r.setNomLieu(rs.getString("lieuNom"));
                reservations.add(r);
            }
        }
        return reservations;
    }

    public Reservation findById(int id) throws SQLException {
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idLieu, r.dateArrivee, l.libelle AS nomLieu " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idLieu = l.id " +
                     "WHERE r.id = ?";
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Reservation reservation = new Reservation();
                    reservation.setId(rs.getInt("id"));
                    reservation.setIdClient(rs.getString("idClient"));
                    reservation.setNbPassager(rs.getInt("nbPassager"));
                    reservation.setIdLieu(rs.getInt("idLieu"));
                    Timestamp ts = rs.getTimestamp("dateArrivee");
                    reservation.setDateArrivee(ts != null ? sdf.format(ts) : null);
                    reservation.setNomLieu(rs.getString("nomLieu"));
                    return reservation;
                }
            }
        }
        return null;
    }

    public List<Reservation> findByDate(String date) throws SQLException {
        System.out.println("[DEBUG] Date reçue dans findByDate : " + date);
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idLieu, r.dateArrivee, l.libelle AS nomLieu " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idLieu = l.id " +
                     "WHERE r.dateArrivee::date = ? " +
                     "ORDER BY r.dateArrivee ASC";
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (date.length() > 10) date = date.substring(0, 10);
            stmt.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Reservation reservation = new Reservation();
                    reservation.setId(rs.getInt("id"));
                    reservation.setIdClient(rs.getString("idClient"));
                    reservation.setNbPassager(rs.getInt("nbPassager"));
                    reservation.setIdLieu(rs.getInt("idLieu"));
                    Timestamp ts = rs.getTimestamp("dateArrivee");
                    reservation.setDateArrivee(ts != null ? sdf.format(ts) : null);
                    reservation.setNomLieu(rs.getString("nomLieu"));
                    reservations.add(reservation);
                }
            }
        }
        System.out.println("[DEBUG] Nombre de réservations trouvées : " + reservations.size());
        return reservations;
    }

    /**
     * Regroupe les réservations par vol.
     *
     * LOGIQUE :
     * - Les réservations sont déjà triées par dateArrivee ASC (fait dans findByDate)
     * - On parcourt chaque réservation et on cherche un groupe existant dont
     *   l'heure de DÉBUT du groupe est dans la fenêtre tempsAttente
     *   (|dateArrivee_reservation - heureDebut_groupe| <= tempsAttente)
     * - Si tempsAttente = 0 : seules les réservations à la même heure EXACTE sont regroupées
     * - Si tempsAttente > 0 : les réservations dans la fenêtre sont regroupées ensemble
     *
     * Exemple tempsAttente=30min :
     *   A(09:00), B(09:00), C(09:30) → même groupe car 09:30 - 09:00 = 30min <= 30min
     *
     * Exemple tempsAttente=0 :
     *   A(09:00), B(09:00), C(09:30) → 2 groupes : {A,B} et {C}
     *
     * Les réservations de chaque groupe sont ensuite triées par nbPassager DÉCROISSANT
     * pour que les plus grosses soient traitées en premier lors de la planification.
     */
    public Map<String, List<Reservation>> regrouperParVol(List<Reservation> reservations, int tempsAttente) {
        Map<String, List<Reservation>> vols = new LinkedHashMap<>();

        for (Reservation reservation : reservations) {
            String heureReservation = reservation.getDateArrivee();
            String heureGroupe = trouverGroupeCompatible(vols, heureReservation, tempsAttente);

            if (heureGroupe != null) {
                ajouterReservationAuGroupe(vols, heureGroupe, reservation);
            } else {
                creerNouveauGroupe(vols, heureReservation, reservation);
            }
        }

        // NOUVEAU : mettre à jour les clés des groupes avec la dernière heure
        mettreAJourHeuresGroupes(vols);
        
        trierGroupesParNbPassagerDesc(vols);
        return vols;
    }

    /**
     * Met à jour les clés des groupes : 
     * - ancienne clé = première heure
     * - nouvelle clé = dernière heure du groupe
     */
    private void mettreAJourHeuresGroupes(Map<String, List<Reservation>> vols) {
        Map<String, List<Reservation>> volsMisAJour = new LinkedHashMap<>();
        
        for (List<Reservation> groupe : vols.values()) {
            String dernierHeure = trouveDerniereHeure(groupe);
            volsMisAJour.put(dernierHeure, groupe);
        }
        
        vols.clear();
        vols.putAll(volsMisAJour);
    }

    /**
     * Trouve l'heure de départ = dernière heure (max) du groupe
     */
    private String trouveDerniereHeure(List<Reservation> groupe) {
        String derniere = groupe.get(0).getDateArrivee();
        for (Reservation r : groupe) {
            if (r.getDateArrivee().compareTo(derniere) > 0) {
                derniere = r.getDateArrivee();
            }
        }
        return derniere;
    }

    private String trouverGroupeCompatible(Map<String, List<Reservation>> vols, String heureReservation, int tempsAttente) {
        for (String heureGroupe : vols.keySet()) {
            long diffMinutes = Math.abs(diffEnMinutes(heureReservation, heureGroupe));
            if (diffMinutes <= tempsAttente) {
                return heureGroupe;
            }
        }
        return null;
    }

    private void ajouterReservationAuGroupe(
            Map<String, List<Reservation>> vols,
            String heureGroupe,
            Reservation reservation) {
        vols.get(heureGroupe).add(reservation);
    }

    private void creerNouveauGroupe(
            Map<String, List<Reservation>> vols,
            String heureReservation,
            Reservation reservation) {
        List<Reservation> newGroupe = new ArrayList<>();
        newGroupe.add(reservation);
        vols.put(heureReservation, newGroupe);
    }

    private void trierGroupesParNbPassagerDesc(Map<String, List<Reservation>> vols) {
        for (List<Reservation> groupe : vols.values()) {
            trierGroupeParNbPassagerDesc(groupe);
        }
    }

    private void trierGroupeParNbPassagerDesc(List<Reservation> groupe) {
        for (int i = 0; i < groupe.size() - 1; i++) {
            for (int j = 0; j < groupe.size() - i - 1; j++) {
                if (groupe.get(j).getNbPassager() < groupe.get(j + 1).getNbPassager()) {
                    Reservation tmp = groupe.get(j);
                    groupe.set(j, groupe.get(j + 1));
                    groupe.set(j + 1, tmp);
                }
            }
        }
    }

    /**
     * Calcule la différence en minutes entre deux dates au format "yyyy-MM-dd HH:mm:ss"
     * Retourne heure2 - heure1 en minutes
     */
    private long diffEnMinutes(String heure1, String heure2) {
        try {
            long ts1 = java.sql.Timestamp.valueOf(heure1).getTime();
            long ts2 = java.sql.Timestamp.valueOf(heure2).getTime();
            return (ts2 - ts1) / (60 * 1000);
        } catch (Exception e) {
            return Long.MAX_VALUE;
        }
    }
}
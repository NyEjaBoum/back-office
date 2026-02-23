package dao;

import model.Reservation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import model.Lieu;

public class ReservationDao {

    public void insert(Reservation reservation) throws SQLException {
        String sql = "INSERT INTO reservation (idClient, nbPassager, idLieu, dateArrivee) VALUES (?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, reservation.getIdClient());
            stmt.setInt(2, reservation.getNbPassager());
                stmt.setInt(3, reservation.getIdLieu()); // À renommer en getIdLieu() dans Reservation si tu veux être cohérent

            // Conversion String -> Timestamp
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
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idLieu, r.dateArrivee, l.id AS lieuId, l.libelle AS lieuNom " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idLieu = l.id " +
                     "ORDER BY r.dateArrivee DESC";

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Reservation reservation = new Reservation();
                reservation.setId(rs.getInt("id"));
                reservation.setIdClient(rs.getString("idClient"));
                reservation.setNbPassager(rs.getInt("nbPassager"));
                    reservation.setIdLieu(rs.getInt("idLieu")); // À renommer en setIdLieu() dans Reservation si tu veux être cohérent

                // Conversion Timestamp -> String
                Timestamp ts = rs.getTimestamp("dateArrivee");
                String dateStr = ts != null ? sdf.format(ts) : null;
                reservation.setDateArrivee(dateStr);

                // Création de l'objet Hotel (à remplacer par Lieu si tu as une classe Lieu)
                    // Lieu lieu = new Lieu();
                    // lieu.setId(rs.getInt("lieuId"));
                    // lieu.setLibelle(rs.getString("lieuNom"));
                    // reservation.setLieu(lieu);

                    reservation.setNomLieu(rs.getString("lieuNom")); // À renommer en setNomLieu() si tu veux être cohérent
                reservations.add(reservation);
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
                        reservation.setIdLieu(rs.getInt("idLieu")); // À renommer en setIdLieu()

                    // Conversion Timestamp -> String
                    Timestamp ts = rs.getTimestamp("dateArrivee");
                    String dateStr = ts != null ? sdf.format(ts) : null;
                    reservation.setDateArrivee(dateStr);

                        reservation.setNomLieu(rs.getString("nomLieu")); // À renommer en setNomLieu()
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
            // S'assurer que date est bien au format "yyyy-MM-dd"
            if (date.length() > 10) date = date.substring(0, 10);
            stmt.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Reservation reservation = new Reservation();
                    reservation.setId(rs.getInt("id"));
                    reservation.setIdClient(rs.getString("idClient"));
                    reservation.setNbPassager(rs.getInt("nbPassager"));
                        reservation.setIdLieu(rs.getInt("idLieu")); // À renommer en setIdLieu()
                    // Conversion Timestamp -> String
                    java.sql.Timestamp ts = rs.getTimestamp("dateArrivee");
                    String dateStr = ts != null ? sdf.format(ts) : null;
                    reservation.setDateArrivee(dateStr);
                        reservation.setNomLieu(rs.getString("nomLieu")); // À renommer en setNomLieu()
                    reservations.add(reservation);
                }
            }
        }
        System.out.println("[DEBUG] Nombre de réservations trouvées : " + reservations.size());
        return reservations;
    }

    /**
     * Regroupe les réservations selon les règles métier :
     * - Tri par heure d'arrivée
     * - Regroupement selon tempsAttente
     * - Jamais diviser une réservation
     * (La capacité du véhicule sera vérifiée lors de l'assignation)
     */
    public List<List<Reservation>> regrouperReservations(List<Reservation> reservations, int tempsAttente) {
        trierParHeureArrivee(reservations);
        List<List<Reservation>> groupes = new ArrayList<>();
        for (Reservation r : reservations) {
            boolean added = false;
            for (List<Reservation> groupe : groupes) {
                if (peutAjouterAuGroupe(groupe, r, tempsAttente)) {
                    groupe.add(r);
                    added = true;
                    break;
                }
            }
            if (!added) {
                List<Reservation> newGroupe = new ArrayList<>();
                newGroupe.add(r);
                groupes.add(newGroupe);
            }
        }
        return groupes;
    }

    /** Trie la liste par heure d'arrivée (bubble sort pour éviter Comparator) */
    private void trierParHeureArrivee(List<Reservation> reservations) {
        for (int i = 0; i < reservations.size() - 1; i++) {
            for (int j = 0; j < reservations.size() - i - 1; j++) {
                String date1 = reservations.get(j).getDateArrivee();
                String date2 = reservations.get(j + 1).getDateArrivee();
                if (date1.compareTo(date2) > 0) {
                    Reservation tmp = reservations.get(j);
                    reservations.set(j, reservations.get(j + 1));
                    reservations.set(j + 1, tmp);
                }
            }
        }
    }

    /** Vérifie si on peut ajouter la réservation r au groupe selon l'écart d'heure d'arrivée */
    private boolean peutAjouterAuGroupe(List<Reservation> groupe, Reservation r, int tempsAttente) {
        if (groupe.isEmpty()) return true;
        Reservation first = groupe.get(0);
        long diff = Math.abs(
            java.sql.Timestamp.valueOf(r.getDateArrivee()).getTime() -
            java.sql.Timestamp.valueOf(first.getDateArrivee()).getTime()
        ) / (60 * 1000); // minutes
        return diff <= tempsAttente;
    }
}
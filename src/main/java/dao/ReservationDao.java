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

public class ReservationDao {

    public void insert(Reservation reservation) throws SQLException {
        String sql = "INSERT INTO reservation (idClient, nbPassager, idHotel, dateArrivee) VALUES (?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, reservation.getIdClient());
            stmt.setInt(2, reservation.getNbPassager());
            stmt.setInt(3, reservation.getIdHotel());

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
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idHotel, r.dateArrivee, h.nom AS nomHotel " +
                     "FROM reservation r " +
                     "JOIN hotel h ON r.idHotel = h.id " +
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
                reservation.setIdHotel(rs.getInt("idHotel"));

                // Conversion Timestamp -> String
                Timestamp ts = rs.getTimestamp("dateArrivee");
                String dateStr = ts != null ? sdf.format(ts) : null;
                reservation.setDateArrivee(dateStr);

                reservation.setNomHotel(rs.getString("nomHotel"));
                reservations.add(reservation);
            }
        }
        return reservations;
    }

    public Reservation findById(int id) throws SQLException {
        String sql = "SELECT r.id, r.idClient, r.nbPassager, r.idHotel, r.dateArrivee, h.nom AS nomHotel " +
                     "FROM reservation r " +
                     "JOIN hotel h ON r.idHotel = h.id " +
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
                    reservation.setIdHotel(rs.getInt("idHotel"));

                    // Conversion Timestamp -> String
                    Timestamp ts = rs.getTimestamp("dateArrivee");
                    String dateStr = ts != null ? sdf.format(ts) : null;
                    reservation.setDateArrivee(dateStr);

                    reservation.setNomHotel(rs.getString("nomHotel"));
                    return reservation;
                }
            }
        }
        return null;
    }
}
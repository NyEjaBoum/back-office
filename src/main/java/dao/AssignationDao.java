package dao;

import model.Assignation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class AssignationDao {

    /**
     * Supprime toutes les assignations liées aux réservations d'une date donnée.
     * Appelé au début de chaque génération.
     *
     * @param date au format "yyyy-MM-dd"
     * @throws SQLException en cas d'erreur base de données
     */
    public void supprimerParDate(String date) throws SQLException {
        String sql = "DELETE FROM assignation a USING reservation r " +
                     "WHERE a.idReservation = r.id AND DATE(r.dateArrivee) = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (date.length() > 10) date = date.substring(0, 10);
            stmt.setDate(1, java.sql.Date.valueOf(date));
            stmt.executeUpdate();
        }
    }

    /**
     * Insère une nouvelle assignation en base.
     * La réservation peut être fractionnée : nbPassagerAffecte != reservation.nbPassager
     *
     * @param assignation l'assignation à insérer
     * @throws SQLException en cas d'erreur base de données
     */
    public void insert(Assignation assignation) throws SQLException {
        String sql = "INSERT INTO assignation (idVehicule, idReservation, nbPassagerAffecte, decalee) VALUES (?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, assignation.getIdVehicule());
            stmt.setInt(2, assignation.getIdReservation());
            stmt.setInt(3, assignation.getNbPassagerAffecte());
            stmt.setBoolean(4, assignation.isDecalee());
            stmt.executeUpdate();
        }
    }

    /**
     * Retourne toutes les assignations liées aux réservations d'une date donnée.
     *
     * @param date au format "yyyy-MM-dd"
     * @return liste des assignations pour cette date
     * @throws SQLException en cas d'erreur base de données
     */
    public List<Assignation> findByDate(String date) throws SQLException {
        List<Assignation> assignations = new ArrayList<>();
        String sql = "SELECT a.id, a.idVehicule, a.idReservation, a.nbPassagerAffecte, a.decalee, a.datePlanification " +
                     "FROM assignation a " +
                     "JOIN reservation r ON a.idReservation = r.id " +
                     "WHERE DATE(r.dateArrivee) = ? " +
                     "ORDER BY a.id ASC";

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (date.length() > 10) date = date.substring(0, 10);
            stmt.setDate(1, java.sql.Date.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Assignation a = new Assignation();
                    a.setId(rs.getInt("id"));
                    a.setIdVehicule(rs.getInt("idVehicule"));
                    a.setIdReservation(rs.getInt("idReservation"));
                    a.setNbPassagerAffecte(rs.getInt("nbPassagerAffecte"));
                    a.setDecalee(rs.getBoolean("decalee"));
                    Timestamp ts = rs.getTimestamp("datePlanification");
                    a.setDatePlanification(ts != null ? sdf.format(ts) : null);
                    assignations.add(a);
                }
            }
        }

        return assignations;
    }

    /**
     * Retourne une assignation par son ID.
     *
     * @param id l'identifiant de l'assignation
     * @return l'assignation trouvée, ou null si non trouvée
     * @throws SQLException en cas d'erreur base de données
     */
    public Assignation findById(int id) throws SQLException {
        String sql = "SELECT id, idVehicule, idReservation, nbPassagerAffecte, decalee, datePlanification " +
                     "FROM assignation WHERE id = ?";

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Assignation a = new Assignation();
                    a.setId(rs.getInt("id"));
                    a.setIdVehicule(rs.getInt("idVehicule"));
                    a.setIdReservation(rs.getInt("idReservation"));
                    a.setNbPassagerAffecte(rs.getInt("nbPassagerAffecte"));
                    a.setDecalee(rs.getBoolean("decalee"));
                    Timestamp ts = rs.getTimestamp("datePlanification");
                    a.setDatePlanification(ts != null ? sdf.format(ts) : null);
                    return a;
                }
            }
        }

        return null;
    }

    /**
     * Retourne toutes les assignations.
     *
     * @return liste de toutes les assignations
     * @throws SQLException en cas d'erreur base de données
     */
    public List<Assignation> findAll() throws SQLException {
        List<Assignation> assignations = new ArrayList<>();
        String sql = "SELECT id, idVehicule, idReservation, nbPassagerAffecte, decalee, datePlanification " +
                     "FROM assignation ORDER BY id ASC";

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Assignation a = new Assignation();
                a.setId(rs.getInt("id"));
                a.setIdVehicule(rs.getInt("idVehicule"));
                a.setIdReservation(rs.getInt("idReservation"));
                a.setNbPassagerAffecte(rs.getInt("nbPassagerAffecte"));
                a.setDecalee(rs.getBoolean("decalee"));
                Timestamp ts = rs.getTimestamp("datePlanification");
                a.setDatePlanification(ts != null ? sdf.format(ts) : null);
                assignations.add(a);
            }
        }

        return assignations;
    }

    /**
     * Met à jour une assignation.
     *
     * @param assignation l'assignation à mettre à jour
     * @throws SQLException en cas d'erreur base de données
     */
    public void update(Assignation assignation) throws SQLException {
        String sql = "UPDATE assignation SET idVehicule = ?, idReservation = ?, nbPassagerAffecte = ?, decalee = ? WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, assignation.getIdVehicule());
            stmt.setInt(2, assignation.getIdReservation());
            stmt.setInt(3, assignation.getNbPassagerAffecte());
            stmt.setBoolean(4, assignation.isDecalee());
            stmt.setInt(5, assignation.getId());
            stmt.executeUpdate();
        }
    }

    /**
     * Supprime une assignation par son ID.
     *
     * @param id l'identifiant de l'assignation
     * @throws SQLException en cas d'erreur base de données
     */
    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM assignation WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            stmt.executeUpdate();
        }
    }
}

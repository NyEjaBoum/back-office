package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DistanceDao {

    /**
     * Retourne la distance (km) entre deux lieux (idFrom, idTo)
     */
    public double getDistance(int idFrom, int idTo) throws SQLException {
        String sql = "SELECT km FROM distance WHERE (\"from\" = ? AND \"to\" = ?) OR (\"from\" = ? AND \"to\" = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, idFrom);
            stmt.setInt(2, idTo);
            stmt.setInt(3, idTo);
            stmt.setInt(4, idFrom);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble("km");
                }
            }
        }
        return -1; // ou Double.MAX_VALUE si non trouvé
    }
}
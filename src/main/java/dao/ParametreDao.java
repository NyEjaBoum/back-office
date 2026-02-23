package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ParametreDao {
    public int getTempsAttente() throws SQLException {
        String sql = "SELECT tempsAttente FROM parametre LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) return rs.getInt("tempsAttente");
        }
        return 30; // valeur par défaut
    }

    public double getVitesseMoyenne() throws SQLException {
        String sql = "SELECT vitesseMoyenne FROM parametre LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) return rs.getDouble("vitesseMoyenne");
        }
        return 40.0; // valeur par défaut
    }
}
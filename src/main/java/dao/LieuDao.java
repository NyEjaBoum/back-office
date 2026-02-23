package dao;

import model.Lieu;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LieuDao {

    public List<Lieu> findAll() throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        String sql = "SELECT id, code, libelle FROM lieu ORDER BY libelle";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Lieu lieu = new Lieu();
                lieu.setId(rs.getInt("id"));
                lieu.setCode(rs.getString("code"));
                lieu.setLibelle(rs.getString("libelle"));
                lieux.add(lieu);
            }
        }
        return lieux;
    }

    public Lieu findById(int id) throws SQLException {
        String sql = "SELECT id, code, libelle FROM lieu WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Lieu lieu = new Lieu();
                    lieu.setId(rs.getInt("id"));
                    lieu.setCode(rs.getString("code"));
                    lieu.setLibelle(rs.getString("libelle"));
                    return lieu;
                }
            }
        }
        return null;
    }
}
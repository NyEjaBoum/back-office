package dao;

import model.Lieu;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LieuDao {

    public List<Lieu> findAll() throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        String sql = "SELECT id, code, libelle, idTypeLieu FROM lieu ORDER BY libelle";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Lieu lieu = new Lieu();
                lieu.setId(rs.getInt("id"));
                lieu.setCode(rs.getString("code"));
                lieu.setLibelle(rs.getString("libelle"));
                lieu.setIdTypeLieu(rs.getInt("idTypeLieu"));
                lieux.add(lieu);
            }
        }
        return lieux;
    }

    public Lieu findByCode(String code) throws SQLException {
        String sql = "SELECT id, code, libelle, idTypeLieu FROM lieu WHERE code = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, code);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Lieu lieu = new Lieu();
                    lieu.setId(rs.getInt("id"));
                    lieu.setCode(rs.getString("code"));
                    lieu.setLibelle(rs.getString("libelle"));
                    lieu.setIdTypeLieu(rs.getInt("idTypeLieu"));
                    return lieu;
                }
            }
        }
        return null;
    }

    public Lieu findById(int id) throws SQLException {
        String sql = "SELECT id, code, libelle, idTypeLieu FROM lieu WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Lieu lieu = new Lieu();
                    lieu.setId(rs.getInt("id"));
                    lieu.setCode(rs.getString("code"));
                    lieu.setLibelle(rs.getString("libelle"));
                    lieu.setIdTypeLieu(rs.getInt("idTypeLieu"));
                    return lieu;
                }
            }
        }
        return null;
    }

    /**
     * Retourne tous les lieux d'un type donné (ex: 'AEROPORT', 'HOTEL')
     */
    public List<Lieu> findByType(String codeType) throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        String sql = "SELECT l.id, l.code, l.libelle, l.idTypeLieu " +
                     "FROM lieu l " +
                     "JOIN type_lieu t ON l.idTypeLieu = t.id " +
                     "WHERE t.code = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, codeType);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Lieu lieu = new Lieu();
                    lieu.setId(rs.getInt("id"));
                    lieu.setCode(rs.getString("code"));
                    lieu.setLibelle(rs.getString("libelle"));
                    lieu.setIdTypeLieu(rs.getInt("idTypeLieu"));
                    lieux.add(lieu);
                }
            }
        }
        return lieux;
    }
}
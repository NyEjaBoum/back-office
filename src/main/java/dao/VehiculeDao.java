package dao;

import model.Vehicule;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class VehiculeDao {

    public List<Vehicule> findAll() throws SQLException {
        List<Vehicule> list = new ArrayList<>();
        String sql = "SELECT id, reference, nbrPlace, typeCarburant FROM vehicule ORDER BY id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Vehicule v = new Vehicule();
                v.setId(rs.getInt("id"));
                v.setReference(rs.getString("reference"));
                v.setNbrPlace(rs.getInt("nbrPlace"));
                v.setTypeCarburant(rs.getString("typeCarburant"));
                list.add(v);
            }
        }
        return list;
    }

    public Vehicule findById(int id) throws SQLException {
        String sql = "SELECT id, reference, nbrPlace, typeCarburant FROM vehicule WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Vehicule v = new Vehicule();
                    v.setId(rs.getInt("id"));
                    v.setReference(rs.getString("reference"));
                    v.setNbrPlace(rs.getInt("nbrPlace"));
                    v.setTypeCarburant(rs.getString("typeCarburant"));
                    return v;
                }
            }
        }
        return null;
    }

    public void insert(Vehicule v) throws SQLException {
        String sql = "INSERT INTO vehicule (reference, nbrPlace, typeCarburant) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, v.getReference());
            stmt.setInt(2, v.getNbrPlace());
            stmt.setString(3, v.getTypeCarburant());
            stmt.executeUpdate();
        }
    }

    public void update(Vehicule v) throws SQLException {
        String sql = "UPDATE vehicule SET reference = ?, nbrPlace = ?, typeCarburant = ? WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, v.getReference());
            stmt.setInt(2, v.getNbrPlace());
            stmt.setString(3, v.getTypeCarburant());
            stmt.setInt(4, v.getId());
            stmt.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM vehicule WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            stmt.executeUpdate();
        }
    }
}
package dao;

import model.Hotel;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class HotelDao {

    public List<Hotel> findAll() throws SQLException {
        List<Hotel> hotels = new ArrayList<>();
        String sql = "SELECT id, nom FROM hotel ORDER BY nom";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getInt("id"));
                hotel.setNom(rs.getString("nom"));
                hotels.add(hotel);
            }
        }
        return hotels;
    }

    public Hotel findById(int id) throws SQLException {
        String sql = "SELECT id, nom FROM hotel WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Hotel hotel = new Hotel();
                    hotel.setId(rs.getInt("id"));
                    hotel.setNom(rs.getString("nom"));
                    return hotel;
                }
            }
        }
        return null;
    }
}

package dao;

import model.Token;
import java.sql.*;
import java.util.UUID;

public class TokenDao {

    public Token findLastToken() throws SQLException {
        String sql = "SELECT id, token, date_expiration FROM token ORDER BY id DESC LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                Token t = new Token();
                t.setId(rs.getInt("id"));
                t.setToken(rs.getString("token"));
                t.setDateExpiration(rs.getTimestamp("date_expiration"));
                return t;
            }
        }
        return null;
    }

    public Token findByToken(String tokenValue) throws SQLException {
        String sql = "SELECT id, token, date_expiration FROM token WHERE token = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setObject(1, UUID.fromString(tokenValue));
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Token t = new Token();
                    t.setId(rs.getInt("id"));
                    t.setToken(rs.getString("token"));
                    t.setDateExpiration(rs.getTimestamp("date_expiration"));
                    return t;
                }
            }
        }
        return null;
    }

    public void insert(Token token) throws SQLException {
        String sql = "INSERT INTO token (token, date_expiration) VALUES (?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setObject(1, UUID.fromString(token.getToken()));
            stmt.setTimestamp(2, token.getDateExpiration());
            stmt.executeUpdate();
        }
    }
}
package model;

import java.sql.Timestamp;

public class Token {
    private int id;
    private String token;
    private Timestamp dateExpiration;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public Timestamp getDateExpiration() { return dateExpiration; }
    public void setDateExpiration(Timestamp dateExpiration) { this.dateExpiration = dateExpiration; }
}
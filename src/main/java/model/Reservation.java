package model;

import java.sql.Timestamp;

public class Reservation {
    private int id;
    private String idClient;
    private int nbPassager;
    private int idHotel;
    private String dateArrivee;
    
    // Pour l'affichage avec les infos de l'hôtel
    private String nomHotel;

    public Reservation() {
    }

    public Reservation(int id, String idClient, int nbPassager, int idHotel, String dateArrivee) {
        this.id = id;
        this.idClient = idClient;
        this.nbPassager = nbPassager;
        this.idHotel = idHotel;
        this.dateArrivee = dateArrivee;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getIdClient() {
        return idClient;
    }

    public void setIdClient(String idClient) {
        this.idClient = idClient;
    }

    public int getNbPassager() {
        return nbPassager;
    }

    public void setNbPassager(int nbPassager) {
        this.nbPassager = nbPassager;
    }

    public int getIdHotel() {
        return idHotel;
    }

    public void setIdHotel(int idHotel) {
        this.idHotel = idHotel;
    }

    public String getDateArrivee() {
        return dateArrivee;
    }

    public void setDateArrivee(String dateArrivee) {
        this.dateArrivee = dateArrivee;
    }

    public String getNomHotel() {
        return nomHotel;
    }

    public void setNomHotel(String nomHotel) {
        this.nomHotel = nomHotel;
    }

    @Override
    public String toString() {
        return "Reservation{id=" + id + ", idClient='" + idClient + "', nbPassager=" + nbPassager + 
               ", idHotel=" + idHotel + ", dateArrivee=" + dateArrivee + ", nomHotel='" + nomHotel + "'}";
    }
}

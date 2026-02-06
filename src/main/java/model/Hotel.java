package model;

public class Hotel {
    private int id;
    private String nom;

    public Hotel() {
    }

    public Hotel(int id, String nom) {
        this.id = id;
        this.nom = nom;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    @Override
    public String toString() {
        return "Hotel{id=" + id + ", nom='" + nom + "'}";
    }
}

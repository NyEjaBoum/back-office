package model;

public class Vehicule {
    private int id;
    private String reference;
    private int nbrPlace;
    private String typeCarburant; // D, ES, H

    public Vehicule() {}

    public Vehicule(int id, String reference, int nbrPlace, String typeCarburant) {
        this.id = id;
        this.reference = reference;
        this.nbrPlace = nbrPlace;
        this.typeCarburant = typeCarburant;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getReference() {
        return reference;
    }

    public void setReference(String reference) {
        this.reference = reference;
    }

    public int getNbrPlace() {
        return nbrPlace;
    }

    public void setNbrPlace(int nbrPlace) {
        this.nbrPlace = nbrPlace;
    }

    public String getTypeCarburant() {
        return typeCarburant;
    }

    public void setTypeCarburant(String typeCarburant) {
        this.typeCarburant = typeCarburant;
    }

    @Override
    public String toString() {
        return "Vehicule{id=" + id + ", reference='" + reference + "', nbrPlace=" + nbrPlace +
               ", typeCarburant='" + typeCarburant + "'}";
    }
}
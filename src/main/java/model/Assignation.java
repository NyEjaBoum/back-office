package model;

public class Assignation {
    private int id;
    private int idVehicule;
    private int idReservation;
    private int nbPassagerAffecte;
    private boolean decalee;
    private String datePlanification;

    // Constructeurs
    public Assignation() {}

    public Assignation(int id, int idVehicule, int idReservation, int nbPassagerAffecte, boolean decalee, String datePlanification) {
        this.id = id;
        this.idVehicule = idVehicule;
        this.idReservation = idReservation;
        this.nbPassagerAffecte = nbPassagerAffecte;
        this.decalee = decalee;
        this.datePlanification = datePlanification;
    }

    public Assignation(int idVehicule, int idReservation, int nbPassagerAffecte, boolean decalee) {
        this.idVehicule = idVehicule;
        this.idReservation = idReservation;
        this.nbPassagerAffecte = nbPassagerAffecte;
        this.decalee = decalee;
    }

    // Getters et Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getIdVehicule() {
        return idVehicule;
    }

    public void setIdVehicule(int idVehicule) {
        this.idVehicule = idVehicule;
    }

    public int getIdReservation() {
        return idReservation;
    }

    public void setIdReservation(int idReservation) {
        this.idReservation = idReservation;
    }

    public int getNbPassagerAffecte() {
        return nbPassagerAffecte;
    }

    public void setNbPassagerAffecte(int nbPassagerAffecte) {
        this.nbPassagerAffecte = nbPassagerAffecte;
    }

    public boolean isDecalee() {
        return decalee;
    }

    public void setDecalee(boolean decalee) {
        this.decalee = decalee;
    }

    public String getDatePlanification() {
        return datePlanification;
    }

    public void setDatePlanification(String datePlanification) {
        this.datePlanification = datePlanification;
    }

    @Override
    public String toString() {
        return "Assignation{" +
                "id=" + id +
                ", idVehicule=" + idVehicule +
                ", idReservation=" + idReservation +
                ", nbPassagerAffecte=" + nbPassagerAffecte +
                ", decalee=" + decalee +
                ", datePlanification='" + datePlanification + '\'' +
                '}';
    }
}

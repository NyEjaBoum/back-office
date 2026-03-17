package model;

public class Reservation {
    private int id;
    private String idClient;
    private int nbPassager;
    private int idLieu;
    private String dateArrivee;

    // Pour l'affichage avec les infos du lieu
    private String nomLieu;

    // Flag pour les réservations reportées à un groupe horaire ultérieur
    private boolean decalee;

    public Reservation() {}

    public Reservation(int id, String idClient, int nbPassager, int idLieu, String dateArrivee, String nomLieu) {
        this.id = id;
        this.idClient = idClient;
        this.nbPassager = nbPassager;
        this.idLieu = idLieu;
        this.dateArrivee = dateArrivee;
        this.nomLieu = nomLieu;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getIdClient() { return idClient; }
    public void setIdClient(String idClient) { this.idClient = idClient; }

    public int getNbPassager() { return nbPassager; }
    public void setNbPassager(int nbPassager) { this.nbPassager = nbPassager; }

    public int getIdLieu() { return idLieu; }
    public void setIdLieu(int idLieu) { this.idLieu = idLieu; }

    public String getDateArrivee() { return dateArrivee; }
    public void setDateArrivee(String dateArrivee) { this.dateArrivee = dateArrivee; }

    public String getNomLieu() { return nomLieu; }
    public void setNomLieu(String nomLieu) { this.nomLieu = nomLieu; }

    public boolean isDecalee() { return decalee; }
    public void setDecalee(boolean decalee) { this.decalee = decalee; }

    @Override
    public String toString() {
        return "Reservation{id=" + id + ", idClient='" + idClient + "', nbPassager=" + nbPassager +
               ", idLieu=" + idLieu + ", dateArrivee=" + dateArrivee + ", nomLieu='" + nomLieu + "'}";
    }
}
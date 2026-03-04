package model;

public class Lieu {
    private int id;
    private String code;
    private String libelle;
    private int idTypeLieu;

    public Lieu() {}

    public Lieu(int id, String code, String libelle) {
        this.id = id;
        this.code = code;
        this.libelle = libelle;
    }

    public Lieu(int id, String code, String libelle, int idTypeLieu) {
        this.id = id;
        this.code = code;
        this.libelle = libelle;
        this.idTypeLieu = idTypeLieu;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }

    public int getIdTypeLieu() { return idTypeLieu; }
    public void setIdTypeLieu(int idTypeLieu) { this.idTypeLieu = idTypeLieu; }

    @Override
    public String toString() {
        return "Lieu{id=" + id + ", code='" + code + "', libelle='" + libelle + "', idTypeLieu=" + idTypeLieu + "}";
    }
}
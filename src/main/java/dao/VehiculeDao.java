package dao;

import model.Vehicule;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

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

    /** Filtre les véhicules disponibles dont la capacité >= nb passagers du groupe */
    public List<Vehicule> filtrerVehiculesCandidats(List<Vehicule> vehicules, int nbPassagersGroupe, Set<Integer> vehiculesOccupes) {
        List<Vehicule> candidats = new ArrayList<>();
        for (Vehicule v : vehicules) {
            if (v.getNbrPlace() >= nbPassagersGroupe && !vehiculesOccupes.contains(v.getId())) {
                candidats.add(v);
            }
        }
        return candidats;
    }

    /** Trie les véhicules par capacité croissante */
    public List<Vehicule> trierParCapacite(List<Vehicule> candidats) {
        List<Vehicule> sorted = new ArrayList<>(candidats);
        for (int i = 0; i < sorted.size() - 1; i++) {
            for (int j = 0; j < sorted.size() - i - 1; j++) {
                if (sorted.get(j).getNbrPlace() > sorted.get(j + 1).getNbrPlace()) {
                    Vehicule tmp = sorted.get(j);
                    sorted.set(j, sorted.get(j + 1));
                    sorted.set(j + 1, tmp);
                }
            }
        }
        return sorted;
    }

    /** Sépare Diesel et autres, puis mélange si plusieurs Diesel même capacité */
    public List<Vehicule> prioriserDiesel(List<Vehicule> sorted) {
        List<Vehicule> diesels = new ArrayList<>();
        List<Vehicule> autres = new ArrayList<>();
        for (Vehicule v : sorted) {
            if ("D".equals(v.getTypeCarburant())) {
                diesels.add(v);
            } else {
                autres.add(v);
            }
        }
        // Si plusieurs Diesel avec même capacité, choix aléatoire
        if (diesels.size() > 1 && diesels.get(0).getNbrPlace() == diesels.get(diesels.size() - 1).getNbrPlace()) {
            Collections.shuffle(diesels);
        }
        List<Vehicule> resultat = new ArrayList<>();
        resultat.addAll(diesels);
        resultat.addAll(autres);
        return resultat;
    }

    /** Retourne le meilleur véhicule selon les règles métier */
    public Vehicule choisirVehicule(List<Vehicule> candidats) {
        List<Vehicule> sorted = trierParCapacite(candidats);
        List<Vehicule> prioritaires = prioriserDiesel(sorted);
        return prioritaires.isEmpty() ? null : prioritaires.get(0);
    }
}
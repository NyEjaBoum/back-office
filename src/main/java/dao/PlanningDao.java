package dao;

import model.Assignation;
import model.Lieu;
import model.Reservation;
import model.Vehicule;
import java.util.*;

public class PlanningDao {

    private DistanceDao distanceDao = new DistanceDao();
    private LieuDao lieuDao = new LieuDao();
    private ParametreDao parametreDao = new ParametreDao();
    private AssignationDao assignationDao = new AssignationDao();

    /**
     * Retourne la liste de tous les lieux de type AEROPORT
     */
    private List<Integer> getIdAeroports() throws Exception {
        List<Lieu> aeroports = lieuDao.findByType("AEROPORT");
        if (aeroports.isEmpty()) throw new Exception("Aucun lieu de type AEROPORT trouvé en base");
        List<Integer> ids = new ArrayList<>();
        for (Lieu l : aeroports) ids.add(l.getId());
        return ids;
    }

    /**
     * Trouve l'aéroport le plus proche d'un ensemble de lieux
     * @param lieuxIds Liste des ids de lieux (hôtels)
     * @return L'id de l'aéroport le plus proche
     */
    private int trouverAeroportLePlusProche(List<Integer> lieuxIds) throws Exception {
        List<Integer> aeroports = getIdAeroports();
        if (aeroports.size() == 1) {
            return aeroports.get(0);
        }

        int meilleurAeroport = aeroports.get(0);
        double minDistanceTotale = Double.MAX_VALUE;

        for (Integer idAeroport : aeroports) {
            double distanceTotale = 0.0;
            for (Integer idLieu : lieuxIds) {
                try {
                    double dist = distanceDao.getDistance(idAeroport, idLieu);
                    if (dist >= 0) distanceTotale += dist;
                } catch (Exception e) {
                    // Distance non trouvée, on ignore
                }
            }
            if (distanceTotale < minDistanceTotale) {
                minDistanceTotale = distanceTotale;
                meilleurAeroport = idAeroport;
            }
        }
        return meilleurAeroport;
    }

    /**
     * Calcule la distance totale (greedy nearest neighbor) pour une liste de réservations.
     * Trajet : Aeroport -> lieux -> Aeroport
     * Retourne une Map avec "distanceTotale" (Double) et "ordreTrajet" (List<String> des noms de lieux).
     * En cas d'égalité de distance, le lieu alphabétiquement le plus petit est visité en premier.
     */
    public Map<String, Object> calculerDistanceGreedy(List<Reservation> reservations) throws Exception {
        Map<String, Object> resultat = new HashMap<>();
        List<Integer> lieux = extraireLieuxUniques(reservations);
        if (lieux.isEmpty()) {
            resultat.put("distanceTotale", 0.0);
            resultat.put("ordreTrajet", new ArrayList<String>());
            return resultat;
        }

        // Map idLieu -> nomLieu pour le tri alphabétique en cas d'égalité de distance
        Map<Integer, String> nomParLieu = new HashMap<>();
        for (Reservation r : reservations) {
            if (!nomParLieu.containsKey(r.getIdLieu()) && r.getNomLieu() != null) {
                nomParLieu.put(r.getIdLieu(), r.getNomLieu());
            }
        }

        // Trouver l'aéroport le plus proche des lieux de la réservation
        int idAeroport = trouverAeroportLePlusProche(lieux);

        double total = 0.0;
        List<Integer> nonVisites = new ArrayList<>(lieux);
        List<String> ordreTrajet = new ArrayList<>();

        // Aeroport -> lieu le plus proche (alphabétique si même distance)
        Integer current = null;
        double minDist = Double.MAX_VALUE;
        String nomMin = null;
        for (Integer l : nonVisites) {
            double dist = distanceDao.getDistance(idAeroport, l);
            String nom = nomParLieu.getOrDefault(l, "");
            if (dist >= 0 && (dist < minDist || (dist == minDist && nomMin != null && nom.compareTo(nomMin) < 0))) {
                minDist = dist;
                current = l;
                nomMin = nom;
            }
        }
        if (current == null) {
            resultat.put("distanceTotale", 0.0);
            resultat.put("ordreTrajet", new ArrayList<String>());
            return resultat;
        }
        total += minDist;
        ordreTrajet.add(nomParLieu.getOrDefault(current, "Lieu #" + current));
        nonVisites.remove(current);

        // Greedy : lieu courant -> lieu le plus proche non visité (alphabétique si même distance)
        while (!nonVisites.isEmpty()) {
            Integer next = null;
            minDist = Double.MAX_VALUE;
            nomMin = null;
            for (Integer l : nonVisites) {
                double dist;
                try { dist = distanceDao.getDistance(current, l); }
                catch (Exception e) { dist = Double.MAX_VALUE; }
                String nom = nomParLieu.getOrDefault(l, "");
                if (dist >= 0 && (dist < minDist || (dist == minDist && nomMin != null && nom.compareTo(nomMin) < 0))) {
                    minDist = dist;
                    next = l;
                    nomMin = nom;
                }
            }
            if (next == null) break;
            total += minDist;
            ordreTrajet.add(nomParLieu.getOrDefault(next, "Lieu #" + next));
            current = next;
            nonVisites.remove(next);
        }

        // Dernier lieu -> Aeroport
        double retour = distanceDao.getDistance(current, idAeroport);
        if (retour >= 0) total += retour;

        resultat.put("distanceTotale", total);
        resultat.put("ordreTrajet", ordreTrajet);
        return resultat;
    }

    /** Extrait les lieux uniques d'une liste de réservations */
    private List<Integer> extraireLieuxUniques(List<Reservation> reservations) {
        List<Integer> lieux = new ArrayList<>();
        for (Reservation r : reservations) {
            if (!lieux.contains(r.getIdLieu())) {
                lieux.add(r.getIdLieu());
            }
        }
        return lieux;
    }

    /**
     * PLANIFICATION PRINCIPALE
     *
     * Traite toute la journée d'un coup :
     * - Parcourt tous les groupes horaires triés par heure
     * - Boucle interne au groupe : si un véhicule revient dans la fenêtre, on retente
     * - Report des réservations non assignées au groupe suivant (décalées)
     * - Persistance en base (table assignation)
     * - Choix véhicule : places, puis trajets, puis carburant D > ES > H
     */

    /**
     * Classe interne pour tracker une fraction de réservation assignée.
     * Permet de gérer le fractionnement : une réservation peut être divisée sur plusieurs véhicules.
     * Chaque fraction créera une ligne separate dans la table assignation.
     */
    private static class ReservationAffectee {
        private Reservation reservation;
        private int nbPassagerAffecte;  // nombre réel assigné à cette fraction

        public ReservationAffectee(Reservation reservation, int nbPassagerAffecte) {
            this.reservation = reservation;
            this.nbPassagerAffecte = nbPassagerAffecte;
        }

        public Reservation getReservation() {
            return reservation;
        }

        public int getNbPassagerAffecte() {
            return nbPassagerAffecte;
        }
    }

    /**
     * Assigne une fraction de réservation à un véhicule.
     * Cette méthode est appelée pour CHAQUE fraction (en cas de fractionnement).
     *
     * @param assignationsVol map idVehicule -> liste de fractions
     * @param placesRestantes map idVehicule -> places encore disponibles
     * @param vehiculeChoisiId id du véhicule recevant la fraction
     * @param reservation la réservation parente (peut être fractionnée)
     * @param nbPassagersAffectes nombre de passagers de cette fraction
     */
    private void assignerFraction(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            Integer vehiculeChoisiId,
            Reservation reservation,
            int nbPassagersAffectes) {
        // Initialiser la liste pour ce véhicule s'il ne l'est pas déjà
        if (!assignationsVol.containsKey(vehiculeChoisiId)) {
            assignationsVol.put(vehiculeChoisiId, new ArrayList<>());
        }

        // Ajouter la fraction à la liste du véhicule
        assignationsVol.get(vehiculeChoisiId)
                .add(new ReservationAffectee(reservation, nbPassagersAffectes));

        // Décrémenter les places restantes du véhicule
        placesRestantes.put(
                vehiculeChoisiId,
                placesRestantes.get(vehiculeChoisiId) - nbPassagersAffectes
        );
    }

    public Map<String, Object> planifier(
            String date,
            Map<String, List<Reservation>> vols,
            List<Vehicule> vehicules) throws Exception {

        // ÉTAPE 1 : Supprimer les anciennes assignations de la date
        assignationDao.supprimerParDate(date);

        double vitesseMoyenne = parametreDao.getVitesseMoyenne();
        int tempsAttente = parametreDao.getTempsAttente();

        List<Map<String, Object>> trajets = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();

        // ÉTAPE 2 : Initialiser les compteurs
        Map<Integer, String> vehiculeHeureRetour = new HashMap<>();
        Map<Integer, Integer> trajetsParVehicule = new HashMap<>();
        for (Vehicule v : vehicules) {
            trajetsParVehicule.put(v.getId(), 0);
        }
        List<Reservation> reservationsEnAttente = new ArrayList<>();

        // ÉTAPE 3 : Parcourir TOUS les groupes horaires de la journée (triés par heure)
        List<String> heuresGroupes = new ArrayList<>(vols.keySet());
        Collections.sort(heuresGroupes);

        for (int idxGroupe = 0; idxGroupe < heuresGroupes.size(); idxGroupe++) {
            String heureDepart = heuresGroupes.get(idxGroupe);
            List<Reservation> reservationsBase = vols.get(heureDepart);
            List<Reservation> reservationsGroupe = new ArrayList<>();
            if (reservationsBase != null) {
                reservationsGroupe.addAll(reservationsBase);
            }

            // Ajouter les réservations en attente des groupes précédents
            reservationsGroupe.addAll(reservationsEnAttente);
            reservationsEnAttente = new ArrayList<>();

            if (reservationsGroupe.isEmpty()) {
                continue;
            }

            // Sprint 8: Trier avec priorité aux réservations décalées, puis par nbPassager DESC
            trierAvecPrioriteDecalees(reservationsGroupe);

            // Fenêtre de regroupement (Sprint 8)
            String heureDepartEffective = heureDepart;
            String heureFinGroupe = ajouterMinutes(heureDepartEffective, tempsAttente);
            List<Reservation> nonAssigneesGroupe = new ArrayList<>(reservationsGroupe);

            // Sprint 8: si on a des décalées mais aucun véhicule n'est disponible au début,
            // on démarre le regroupement au premier retour/disponibilité dans la fenêtre.
            boolean contientReservationsDecalees = false;
            for (Reservation reservation : nonAssigneesGroupe) {
                if (reservation.isDecalee()) {
                    contientReservationsDecalees = true;
                    break;
                }
            }
            if (contientReservationsDecalees) {
                // Si un véhicule est déjà disponible AVANT l'heure du groupe,
                // le regroupement doit démarrer dès cette disponibilité (pas attendre l'heure du groupe).
                // Exemple : véhicule dispo 10:00, groupe 10:10, réservation décalée déjà prête => départ possible à 10:00.
                String debutDecalees = calculerDebutFenetrePourDecalees(
                        nonAssigneesGroupe,
                        vehiculeHeureRetour,
                        vehicules,
                        heureDepart
                );
                if (debutDecalees != null && debutDecalees.compareTo(heureDepartEffective) < 0) {
                    heureDepartEffective = debutDecalees;
                    heureFinGroupe = ajouterMinutes(heureDepartEffective, tempsAttente);
                }

                Map<Integer, Integer> placesAuDebut = initialiserPlacesRestantes(vehicules, vehiculeHeureRetour, heureDepartEffective);
                if (placesAuDebut.isEmpty()) {
                    String premiereDisponibilite = trouverProchaineDisponibiliteDansFenetre(
                            vehiculeHeureRetour,
                            vehicules,
                            heureDepartEffective,
                            heureFinGroupe
                    );
                    if (premiereDisponibilite != null) {
                        heureDepartEffective = premiereDisponibilite;
                        heureFinGroupe = ajouterMinutes(heureDepartEffective, tempsAttente);
                    }
                }
            }

            // Absorber les groupes futurs dont l'heure tombe dans la fenêtre initiale/ajustée
            for (int k = idxGroupe + 1; k < heuresGroupes.size(); k++) {
                String cleGroupe = heuresGroupes.get(k);
                if (cleGroupe.compareTo(heureFinGroupe) > 0) break;
                List<Reservation> futurs = vols.get(cleGroupe);
                if (futurs != null && !futurs.isEmpty()) {
                    nonAssigneesGroupe.addAll(futurs);
                    futurs.clear();
                }
            }
            trierAvecPrioriteDecalees(nonAssigneesGroupe);

            // BOUCLE INTERNE AU GROUPE
            while (true) {
                Map<Integer, Integer> placesRestantes = initialiserPlacesRestantes(vehicules, vehiculeHeureRetour, heureDepartEffective);
                Map<Integer, List<ReservationAffectee>> assignationsPassage = new LinkedHashMap<>();
                List<Reservation> encoreNonAssignees = new ArrayList<>();

                // Aucun véhicule dispo : attendre un retour/disponibilité dans la fenêtre
                if (placesRestantes.isEmpty()) {
                    String prochaineDisponibilite = trouverProchaineDisponibiliteDansFenetre(
                            vehiculeHeureRetour,
                            vehicules,
                            heureDepartEffective,
                            heureFinGroupe
                    );

                    if (prochaineDisponibilite == null) {
                        for (Reservation r : nonAssigneesGroupe) {
                            r.setDecalee(true);
                            reservationsEnAttente.add(r);
                        }
                        break;
                    }

                    heureDepartEffective = prochaineDisponibilite;
                    heureFinGroupe = ajouterMinutes(heureDepartEffective, tempsAttente);

                    // Absorber les groupes futurs dont l'heure tombe dans la nouvelle fenêtre
                    for (int k = idxGroupe + 1; k < heuresGroupes.size(); k++) {
                        String cleGroupe = heuresGroupes.get(k);
                        if (cleGroupe.compareTo(heureFinGroupe) > 0) break;
                        List<Reservation> futurs = vols.get(cleGroupe);
                        if (futurs != null && !futurs.isEmpty()) {
                            nonAssigneesGroupe.addAll(futurs);
                            futurs.clear();
                        }
                    }

                    trierAvecPrioriteDecalees(nonAssigneesGroupe);
                    continue;
                }

                // Traiter les réservations avec assignation dynamique
                // Map pour suivre combien de passagers restent pour chaque réservation
                Map<Integer, Integer> passagersRestants = new LinkedHashMap<>();
                for (Reservation r : nonAssigneesGroupe) {
                    passagersRestants.put(r.getId(), r.getNbPassager());
                }

                // Si une réservation ne peut pas être assignée d'un seul bloc,
                // on reste en "mode fractionnement" pour toute la réservation
                // (on affecte alors du plus grand véhicule libre au plus petit).
                Map<Integer, Boolean> fractionnementParReservation = new HashMap<>();

                while (!passagersRestants.isEmpty()) {
                    // Traiter les réservations dans l'ordre priorisé du groupe
                    // (triées au préalable par nbPassager DESC), et terminer une
                    // réservation avant de passer à la suivante.
                    Integer idReservationCourante = trouverProchaineReservationDansOrdre(nonAssigneesGroupe, passagersRestants);
                    if (idReservationCourante == null) break;

                    Reservation reservationCourante = trouverReservationParId(nonAssigneesGroupe, idReservationCourante);
                    int reste = passagersRestants.get(idReservationCourante);

                    // Chercher un véhicule pour cette réservation selon les règles Sprint 7 :
                    // 1) essayer une assignation complète sur un seul véhicule (si possible)
                    // 2) sinon fractionner du plus grand au plus petit, et garder ce mode
                    boolean enFractionnement = fractionnementParReservation.getOrDefault(idReservationCourante, false);
                    Integer vehiculeChoisi;

                    if (!enFractionnement) {
                        vehiculeChoisi = choisirVehiculePourReservation(placesRestantes, reste, vehicules, trajetsParVehicule, false);
                        if (vehiculeChoisi == null) {
                            fractionnementParReservation.put(idReservationCourante, true);
                            enFractionnement = true;
                            vehiculeChoisi = choisirVehiculePourReservation(placesRestantes, reste, vehicules, trajetsParVehicule, true);
                        }
                    } else {
                        vehiculeChoisi = choisirVehiculePourReservation(placesRestantes, reste, vehicules, trajetsParVehicule, true);
                    }

                    if (vehiculeChoisi == null) {
                        // Plus de véhicule disponible → reliquat
                        Reservation reliquat = new Reservation();
                        reliquat.setId(reservationCourante.getId());
                        reliquat.setNbPassager(reste);
                        reliquat.setIdClient(reservationCourante.getIdClient());
                        reliquat.setDateArrivee(reservationCourante.getDateArrivee());
                        reliquat.setIdLieu(reservationCourante.getIdLieu());
                        reliquat.setNomLieu(reservationCourante.getNomLieu());
                        reliquat.setDecalee(true);
                        encoreNonAssignees.add(reliquat);
                        passagersRestants.remove(idReservationCourante);
                        continue;
                    }

                    int placesLibres = placesRestantes.get(vehiculeChoisi);
                    int qte = Math.min(reste, placesLibres);

                    assignerFraction(assignationsPassage, placesRestantes, vehiculeChoisi, reservationCourante, qte);
                    assignationDao.insert(new Assignation(vehiculeChoisi, reservationCourante.getId(), qte, reservationCourante.isDecalee()));

                    reste -= qte;

                    // Mettre à jour ou supprimer de la map
                    if (reste == 0) {
                        passagersRestants.remove(idReservationCourante);
                    } else {
                        passagersRestants.put(idReservationCourante, reste);
                    }

                    // Si le véhicule a encore des places, on complète avec la réservation la plus proche
                    // (minimise l'écart de remplissage) pour stabiliser la répartition.
                    while (!passagersRestants.isEmpty() && placesRestantes.get(vehiculeChoisi) != null && placesRestantes.get(vehiculeChoisi) > 0) {
                        int placesDispo = placesRestantes.get(vehiculeChoisi);
                        Integer idPlusProche = trouverReservationLaPlusProche(nonAssigneesGroupe, passagersRestants, placesDispo);
                        if (idPlusProche == null) break;

                        Reservation rProche = trouverReservationParId(nonAssigneesGroupe, idPlusProche);
                        if (rProche == null) {
                            passagersRestants.remove(idPlusProche);
                            continue;
                        }

                        int resteProche = passagersRestants.get(idPlusProche);
                        int qteProche = Math.min(resteProche, placesDispo);

                        assignerFraction(assignationsPassage, placesRestantes, vehiculeChoisi, rProche, qteProche);
                        assignationDao.insert(new Assignation(vehiculeChoisi, rProche.getId(), qteProche, rProche.isDecalee()));

                        resteProche -= qteProche;
                        if (resteProche == 0) {
                            passagersRestants.remove(idPlusProche);
                        } else {
                            passagersRestants.put(idPlusProche, resteProche);
                        }
                    }

                }

                // Incrémenter le compteur de trajets par véhicule
                for (Integer vehiculeId : assignationsPassage.keySet()) {
                    trajetsParVehicule.put(vehiculeId, trajetsParVehicule.get(vehiculeId) + 1);
                }

                // Créer les trajets de CE passage (Sprint 8 : un trajet par passage/regroupement)
                if (!assignationsPassage.isEmpty()) {
                    boolean futureReservations = false;
                    for (int j = idxGroupe + 1; j < heuresGroupes.size(); j++) {
                        List<Reservation> prochaines = vols.get(heuresGroupes.get(j));
                        if (prochaines != null && !prochaines.isEmpty()) {
                            futureReservations = true;
                            break;
                        }
                    }

                    boolean aucuneReservationRestante = encoreNonAssignees.isEmpty() && reservationsEnAttente.isEmpty() && !futureReservations;
                    boolean attendreFinFenetre = !aucuneReservationRestante;

                    creerTrajetsPourVol(
                            heureDepartEffective,
                            heureFinGroupe,
                            assignationsPassage,
                            vehicules,
                            vitesseMoyenne,
                            vehiculeHeureRetour,
                            trajets,
                            heureDepartEffective,
                            attendreFinFenetre
                    );
                }

                // Vérifier si tout est assigné
                if (encoreNonAssignees.isEmpty()) {
                    break;
                }

                // Chercher le prochain véhicule qui se libère / devient dispo dans la fenêtre
                String plusProchaineDisponibilite = trouverProchaineDisponibiliteDansFenetre(
                        vehiculeHeureRetour,
                        vehicules,
                        heureDepartEffective,
                        heureFinGroupe
                );

                if (plusProchaineDisponibilite == null) {
                    // Aucun véhicule ne revient dans la fenêtre
                    // Reporter les non-assignées au prochain groupe (décalées)
                    for (Reservation r : encoreNonAssignees) {
                        r.setDecalee(true);
                        reservationsEnAttente.add(r);
                    }
                    break;
                }

                // Sprint 8: Un véhicule revient → nouveau regroupement avec nouveau temps d'attente
                heureDepartEffective = plusProchaineDisponibilite;
                // La fenêtre s'étend à partir de l'heure de retour du véhicule
                heureFinGroupe = ajouterMinutes(plusProchaineDisponibilite, tempsAttente);

                // Absorber les groupes futurs dont l'heure tombe dans la nouvelle fenêtre
                for (int k = idxGroupe + 1; k < heuresGroupes.size(); k++) {
                    String cleGroupe = heuresGroupes.get(k);
                    if (cleGroupe.compareTo(heureFinGroupe) > 0) break;
                    List<Reservation> futurs = vols.get(cleGroupe);
                    if (futurs != null && !futurs.isEmpty()) {
                        encoreNonAssignees.addAll(futurs);
                        futurs.clear();
                    }
                }

                // Les réservations décalées sont déjà dans encoreNonAssignees
                // Elles seront priorisées grâce au tri trierAvecPrioriteDecalees
                nonAssigneesGroupe = encoreNonAssignees;
                trierAvecPrioriteDecalees(nonAssigneesGroupe);
            }

            // Après le dernier groupe connu, si des réservations restent en attente,
            // on continue à créer des regroupements au retour des véhicules.
            if (idxGroupe == heuresGroupes.size() - 1 && !reservationsEnAttente.isEmpty()) {
                String prochaineDisponibilite = trouverProchaineDisponibiliteApres(
                        vehiculeHeureRetour,
                        vehicules,
                        heureFinGroupe
                );

                if (prochaineDisponibilite != null && !heuresGroupes.contains(prochaineDisponibilite)) {
                    heuresGroupes.add(prochaineDisponibilite);
                } else if (prochaineDisponibilite == null) {
                    nonAssignees.addAll(reservationsEnAttente);
                    reservationsEnAttente = new ArrayList<>();
                }
            }
        }

        // ÉTAPE 4 : Les réservations encore en attente après le DERNIER groupe
        for (Reservation r : reservationsEnAttente) {
            nonAssignees.add(r);
        }

        Map<String, Object> resultat = new HashMap<>();
        resultat.put("trajets", trajets);
        resultat.put("nonAssignees", nonAssignees);
        return resultat;
    }

    private Map<Integer, Integer> initialiserPlacesRestantes(List<Vehicule> vehicules, Map<Integer, String> vehiculeHeureRetour, String heureVol) {
        Map<Integer, Integer> placesRestantes = new HashMap<>();
        for (Vehicule v : vehicules) {
            String heureRetourV = vehiculeHeureRetour.get(v.getId());
            String heureDispoV = v.getHeureDisponibilite();

            // Véhicule disponible si :
            // 1. heureDisponibilite <= heureVol (ou null = toujours dispo)
            // 2. ET heureRetour <= heureVol (ou null = pas encore utilisé)
            boolean dispoParHeure = (heureDispoV == null || heureDispoV.compareTo(heureVol) <= 0);
            boolean dispoParRetour = (heureRetourV == null || heureRetourV.compareTo(heureVol) <= 0);

            if (dispoParHeure && dispoParRetour) {
                placesRestantes.put(v.getId(), v.getNbrPlace());
            }
        }
        return placesRestantes;
    }

    /**
     * Retourne les vehicules disponibles tries par capacite totale decroissante.
     * En cas d'egalite de capacite, on priorise le plus de places restantes puis l'id.
     */
    private List<Integer> trierVehiculesDisponiblesParCapaciteDesc(List<Vehicule> vehicules, Map<Integer, Integer> placesRestantes) {
        List<Vehicule> vehiculesDisponibles = new ArrayList<>();
        for (Vehicule v : vehicules) {
            Integer places = placesRestantes.get(v.getId());
            if (places != null && places > 0) {
                vehiculesDisponibles.add(v);
            }
        }

        vehiculesDisponibles.sort((v1, v2) -> {
            int cmpCapacite = Integer.compare(v2.getNbrPlace(), v1.getNbrPlace());
            if (cmpCapacite != 0) return cmpCapacite;

            int cmpPlacesRestantes = Integer.compare(
                    placesRestantes.get(v2.getId()),
                    placesRestantes.get(v1.getId())
            );
            if (cmpPlacesRestantes != 0) return cmpPlacesRestantes;

            return Integer.compare(v1.getId(), v2.getId());
        });

        List<Integer> ids = new ArrayList<>();
        for (Vehicule v : vehiculesDisponibles) {
            ids.add(v.getId());
        }
        return ids;
    }

    private void creerTrajetsPourVol(
            String fenetreDebut,
            String fenetreFin,
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            List<Vehicule> vehicules,
            double vitesseMoyenne,
            Map<Integer, String> vehiculeHeureRetour,
            List<Map<String, Object>> trajets,
            String groupeHeure,
            boolean attendreFinFenetre) {
        for (Map.Entry<Integer, List<ReservationAffectee>> assignation : assignationsVol.entrySet()) {
            int vehiculeId = assignation.getKey();
            List<ReservationAffectee> fractionsAssignees = assignation.getValue();

            // Extraire les réservations de base pour le calcul de distance
            List<Reservation> reservationsForDistance = new ArrayList<>();
            Map<Integer, Integer> qteParReservation = new HashMap<>();
            List<Map<String, Object>> detailsFractions = new ArrayList<>();  // Pour JSP

            int totalPassagersAffectes = 0;
            String heureArriveeMax = fenetreDebut;
            for (ReservationAffectee fraction : fractionsAssignees) {
                Reservation res = fraction.getReservation();
                reservationsForDistance.add(res);
                int idRes = res.getId();
                int currentQte = qteParReservation.getOrDefault(idRes, 0);
                qteParReservation.put(idRes, currentQte + fraction.getNbPassagerAffecte());

                totalPassagersAffectes += fraction.getNbPassagerAffecte();
                if (res.getDateArrivee() != null && res.getDateArrivee().compareTo(heureArriveeMax) > 0) {
                    heureArriveeMax = res.getDateArrivee();
                }

                // Créer un objet simple pour le JSP avec les infos de la fraction
                Map<String, Object> detailFraction = new LinkedHashMap<>();
                detailFraction.put("id", idRes);
                detailFraction.put("idClient", res.getIdClient());
                detailFraction.put("nomLieu", res.getNomLieu());
                detailFraction.put("dateArrivee", res.getDateArrivee());
                detailFraction.put("decalee", res.isDecalee());
                detailFraction.put("nbPassagerAffecte", fraction.getNbPassagerAffecte());
                detailFraction.put("nbPassagerOriginal", res.getNbPassager());
                detailsFractions.add(detailFraction);
            }

            Vehicule v = trouverVehiculeParId(vehicules, vehiculeId);
            Map<String, Object> infosTrajet = calculerInfosTrajet(reservationsForDistance);

            double distanceTotale = (Double) infosTrajet.get("distanceTotale");
            List<String> ordreTrajet = (List<String>) infosTrajet.get("ordreTrajet");

            // Sprint 8: calcul de l'heure de départ
            String heureDepartTrajet;
            if (v != null && totalPassagersAffectes >= v.getNbrPlace()) {
                // Plein => départ au moment où le véhicule atteint sa capacité
                int cumul = 0;
                String heureFullAt = fenetreDebut;
                for (ReservationAffectee fraction : fractionsAssignees) {
                    cumul += fraction.getNbPassagerAffecte();
                    Reservation res = fraction.getReservation();
                    if (res.getDateArrivee() != null && res.getDateArrivee().compareTo(heureFullAt) > 0) {
                        heureFullAt = res.getDateArrivee();
                    }
                    if (cumul >= v.getNbrPlace()) {
                        break;
                    }
                }
                heureDepartTrajet = (heureFullAt.compareTo(fenetreDebut) > 0) ? heureFullAt : fenetreDebut;
            } else {
                // Pas plein => attendre fin de fenêtre sauf si plus rien à planifier
                if (attendreFinFenetre) {
                    heureDepartTrajet = fenetreFin;
                } else {
                    heureDepartTrajet = (heureArriveeMax.compareTo(fenetreDebut) > 0) ? heureArriveeMax : fenetreDebut;
                }
            }

            String heureRetour = calculerHeureRetour(heureDepartTrajet, distanceTotale, vitesseMoyenne);

            vehiculeHeureRetour.put(vehiculeId, heureRetour);

            Map<String, Object> trajet = new LinkedHashMap<>();
            trajet.put("vehicule", v);
            trajet.put("detailsFractions", detailsFractions);  // Pour JSP - liste simple d'objets Map
            trajet.put("qteParReservation", qteParReservation);  // Pour affichage en JSP
            trajet.put("distanceTotale", distanceTotale);
            trajet.put("ordreTrajet", ordreTrajet);
            trajet.put("heureDepart", heureDepartTrajet);
            trajet.put("heureRetour", heureRetour);
            trajet.put("groupeHeure", groupeHeure);
            trajets.add(trajet);
        }
    }

    private Map<String, Object> calculerInfosTrajet(List<Reservation> reservationsAssignees) {
        Map<String, Object> infosTrajet = new HashMap<>();
        infosTrajet.put("distanceTotale", 0.0);
        infosTrajet.put("ordreTrajet", new ArrayList<String>());

        try {
            Map<String, Object> greedyResult = calculerDistanceGreedy(reservationsAssignees);
            infosTrajet.put("distanceTotale", greedyResult.get("distanceTotale"));
            infosTrajet.put("ordreTrajet", greedyResult.get("ordreTrajet"));
        } catch (Exception e) {
            System.err.println("[PLANNING] Erreur calcul distance: " + e.getMessage());
            e.printStackTrace();
        }

        return infosTrajet;
    }

    private String calculerHeureRetour(String heureDepart, double distanceTotale, double vitesseMoyenne) {
        long dureeMs = (long) ((distanceTotale / vitesseMoyenne) * 3600 * 1000);
        return new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
            .format(new java.util.Date(java.sql.Timestamp.valueOf(heureDepart).getTime() + dureeMs));
    }

    private String trouverProchaineDisponibiliteDansFenetre(
            Map<Integer, String> vehiculeHeureRetour,
            List<Vehicule> vehicules,
            String heureDebut,
            String heureFin) {
        String plusProchaineDisponibilite = null;

        for (Vehicule v : vehicules) {
            String candidate = vehiculeHeureRetour.get(v.getId());
            if (candidate == null) {
                candidate = v.getHeureDisponibilite();
            }

            if (candidate != null && candidate.compareTo(heureDebut) > 0 && candidate.compareTo(heureFin) <= 0) {
                if (plusProchaineDisponibilite == null || candidate.compareTo(plusProchaineDisponibilite) < 0) {
                    plusProchaineDisponibilite = candidate;
                }
            }
        }

        return plusProchaineDisponibilite;
    }

    private String trouverProchaineDisponibiliteApres(
            Map<Integer, String> vehiculeHeureRetour,
            List<Vehicule> vehicules,
            String heureApres) {
        String plusProchaineDisponibilite = null;
        for (Vehicule v : vehicules) {
            String candidate = vehiculeHeureRetour.get(v.getId());
            if (candidate == null) {
                candidate = v.getHeureDisponibilite();
            }

            if (candidate != null && candidate.compareTo(heureApres) > 0) {
                if (plusProchaineDisponibilite == null || candidate.compareTo(plusProchaineDisponibilite) < 0) {
                    plusProchaineDisponibilite = candidate;
                }
            }
        }
        return plusProchaineDisponibilite;
    }

    private String calculerDebutFenetrePourDecalees(
            List<Reservation> reservationsGroupe,
            Map<Integer, String> vehiculeHeureRetour,
            List<Vehicule> vehicules,
            String heureGroupe) {

        String minArrivee = null;
        boolean aDecalees = false;
        for (Reservation r : reservationsGroupe) {
            if (r.isDecalee()) {
                aDecalees = true;
            }
            if (r.getDateArrivee() != null) {
                if (minArrivee == null || r.getDateArrivee().compareTo(minArrivee) < 0) {
                    minArrivee = r.getDateArrivee();
                }
            }
        }

        if (!aDecalees) return null;

        String dispoAvantOuEgale = trouverDisponibiliteAvantOuEgale(
                vehiculeHeureRetour,
                vehicules,
                heureGroupe
        );
        if (dispoAvantOuEgale == null) return null;

        String debut = dispoAvantOuEgale;
        if (minArrivee != null && debut.compareTo(minArrivee) < 0) {
            debut = minArrivee;
        }

        return debut;
    }

    private String trouverDisponibiliteAvantOuEgale(
            Map<Integer, String> vehiculeHeureRetour,
            List<Vehicule> vehicules,
            String heureMax) {
        String plusProche = null;

        for (Vehicule v : vehicules) {
            String candidate = vehiculeHeureRetour.get(v.getId());
            if (candidate == null) {
                candidate = v.getHeureDisponibilite();
            }

            if (candidate == null) {
                continue;
            }

            if (candidate.compareTo(heureMax) <= 0) {
                if (plusProche == null || candidate.compareTo(plusProche) > 0) {
                    plusProche = candidate;
                }
            }
        }

        return plusProche;
    }

    /**
     * Trouve l'ID de la réservation avec le plus de passagers restants.
     */
    private Integer trouverReservationAvecPlusDePassagers(Map<Integer, Integer> passagersRestants) {
        Integer idMax = null;
        int max = 0;
        for (Map.Entry<Integer, Integer> entry : passagersRestants.entrySet()) {
            if (entry.getValue() > max) {
                max = entry.getValue();
                idMax = entry.getKey();
            }
        }
        return idMax;
    }

    /**
     * Trouve la prochaine réservation à traiter selon l'ordre déjà trié du groupe.
     */
    private Integer trouverProchaineReservationDansOrdre(
            List<Reservation> reservationsTriees,
            Map<Integer, Integer> passagersRestants) {
        for (Reservation reservation : reservationsTriees) {
            Integer reste = passagersRestants.get(reservation.getId());
            if (reste != null && reste > 0) {
                return reservation.getId();
            }
        }
        return null;
    }

    /**
     * Choisit un véhicule pour une réservation.
     * - modeFractionnement=false : on exige un véhicule suffisant (places >= nbPassagers)
     * - modeFractionnement=true  : on prend le véhicule avec le plus de places restantes
     */
    private Integer choisirVehiculePourReservation(
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule,
            boolean modeFractionnement) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Vehicule v : vehicules) {
            Integer p = placesRestantes.get(v.getId());
            if (p != null && p > 0) {
                candidats.add(v);
            }
        }

        if (candidats.isEmpty()) return null;

        if (modeFractionnement) {
            trierParPlacesRestantesDesc(candidats, placesRestantes, trajetsParVehicule);
            return candidats.get(0).getId();
        }

        List<Vehicule> suffisants = new ArrayList<>();
        for (Vehicule v : candidats) {
            if (placesRestantes.get(v.getId()) >= nbPassagers) {
                suffisants.add(v);
            }
        }

        if (suffisants.isEmpty()) return null;
        return choisirMeilleurVehicule(suffisants, placesRestantes, trajetsParVehicule);
    }

    /**
     * Trouve l'ID de la réservation la plus proche d'un nombre de places.
     * Critère : écart minimal entre nbPassagersRestants et placesDisponibles.
     */
    private Integer trouverReservationLaPlusProche(
            List<Reservation> reservationsTriees,
            Map<Integer, Integer> passagersRestants,
            int placesDisponibles) {
        Integer idPlusProche = null;
        int ecartMin = Integer.MAX_VALUE;

        for (Map.Entry<Integer, Integer> entry : passagersRestants.entrySet()) {
            Reservation r = trouverReservationParId(reservationsTriees, entry.getKey());
            if (r == null) continue;

            int nbPassagers = entry.getValue();
            int ecart = Math.abs(nbPassagers - placesDisponibles);
            if (ecart < ecartMin) {
                ecartMin = ecart;
                idPlusProche = entry.getKey();
            }
        }
        return idPlusProche;
    }

    /**
     * Trouve une réservation dans une liste par son ID.
     */
    private Reservation trouverReservationParId(List<Reservation> reservations, int id) {
        for (Reservation r : reservations) {
            if (r.getId() == id) return r;
        }
        return null;
    }

    /**
     * Cherche le meilleur véhicule pour un nombre de passagers donné.
     * Même logique que l'originale, appliquée aux fractions :
     *   1. Si un véhicule a placesRestantes >= nbPassagers : choisir celui avec le MOINS de places restantes
     *   2. Sinon : choisir celui avec le PLUS de places restantes (pour mettre le max)
     *   3. En cas d'égalité : moins de trajets, puis priorité carburant D > ES > H
     */
    private Integer chercherMeilleurVehiculePourPassagers(
            Map<Integer, List<ReservationAffectee>> assignationsPassage,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule) {

        // Collecter les véhicules disponibles (places restantes > 0)
        List<Vehicule> candidats = new ArrayList<>();
        for (Vehicule v : vehicules) {
            Integer places = placesRestantes.get(v.getId());
            if (places != null && places > 0) {
                candidats.add(v);
            }
        }

        if (candidats.isEmpty()) return null;

        // Séparer en 2 groupes : ceux avec assez de places, et les autres
        List<Vehicule> suffisants = new ArrayList<>();
        List<Vehicule> insuffisants = new ArrayList<>();

        for (Vehicule v : candidats) {
            int places = placesRestantes.get(v.getId());
            if (places >= nbPassagers) {
                suffisants.add(v);
            } else {
                insuffisants.add(v);
            }
        }

        if (!suffisants.isEmpty()) {
            // Trier par places restantes ASC (le moins de places restantes en premier)
            // En cas d'égalité : moins de trajets, puis carburant D > ES > H
            return choisirMeilleurVehicule(suffisants, placesRestantes, trajetsParVehicule);
        } else {
            // Aucun véhicule avec assez de places
            // Prendre celui avec le PLUS de places restantes (pour mettre le max)
            trierParPlacesRestantesDesc(insuffisants, placesRestantes, trajetsParVehicule);
            return insuffisants.get(0).getId();
        }
    }

    /**
     * Trie les véhicules par places restantes décroissantes.
     * En cas d'égalité : moins de trajets, puis carburant D > ES > H
     */
    private void trierParPlacesRestantesDesc(List<Vehicule> vehicules, Map<Integer, Integer> placesRestantes, Map<Integer, Integer> trajetsParVehicule) {
        for (int i = 0; i < vehicules.size() - 1; i++) {
            for (int j = 0; j < vehicules.size() - i - 1; j++) {
                Vehicule v1 = vehicules.get(j);
                Vehicule v2 = vehicules.get(j + 1);
                int p1 = placesRestantes.get(v1.getId());
                int p2 = placesRestantes.get(v2.getId());

                boolean swap = false;
                if (p1 < p2) {
                    // Plus de places restantes en premier
                    swap = true;
                } else if (p1 == p2) {
                    int t1 = trajetsParVehicule.getOrDefault(v1.getId(), 0);
                    int t2 = trajetsParVehicule.getOrDefault(v2.getId(), 0);
                    if (t1 > t2) {
                        swap = true;
                    } else if (t1 == t2) {
                        if (prioriteCarburant(v1.getTypeCarburant()) < prioriteCarburant(v2.getTypeCarburant())) {
                            swap = true;
                        }
                    }
                }

                if (swap) {
                    vehicules.set(j, v2);
                    vehicules.set(j + 1, v1);
                }
            }
        }
    }

    /**
     * Cherche un véhicule déjà utilisé dans ce vol avec des places restantes > 0.
     * Accepte le fractionnement : peut retourner un véhicule avec places < nbPassagers.
     */
    private Integer chercherVehiculeDejaUtilise(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Integer vid : assignationsVol.keySet()) {
            Integer places = placesRestantes.get(vid);
            if (places != null && places > 0) {  // Changé : accepte n'importe quelle place > 0
                Vehicule v = trouverVehiculeParId(vehicules, vid);
                if (v != null) candidats.add(v);
            }
        }
        return choisirMeilleurVehiculeAvecFractionnement(candidats, placesRestantes, nbPassagers, trajetsParVehicule);
    }

    /**
     * Cherche un nouveau véhicule pas encore utilisé dans ce vol avec des places > 0.
     * Accepte le fractionnement : peut retourner un véhicule avec places < nbPassagers.
     */
    private Integer chercherNouveauVehicule(
            Map<Integer, List<ReservationAffectee>> assignationsVol,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            List<Vehicule> vehicules,
            Map<Integer, Integer> trajetsParVehicule) {

        List<Vehicule> candidats = new ArrayList<>();
        for (Map.Entry<Integer, Integer> entry : placesRestantes.entrySet()) {
            int vid = entry.getKey();
            int places = entry.getValue();
            // Pas encore utilisé dans ce vol ET places > 0
            if (!assignationsVol.containsKey(vid) && places > 0) {  // Changé : accepte n'importe quelle place > 0
                Vehicule v = trouverVehiculeParId(vehicules, vid);
                if (v != null) candidats.add(v);
            }
        }
        return choisirMeilleurVehiculeAvecFractionnement(candidats, placesRestantes, nbPassagers, trajetsParVehicule);
    }

    /**
     * Choisit le meilleur véhicule parmi les candidats, avec support du fractionnement.
     * Logique :
     *   - Si places >= nbPassagers : choisir le moins de places restantes (ajusté au mieux)
     *   - Sinon : choisir le plus de places restantes (pour mettre le max)
     *   - En cas d'égalité : moins de trajets, puis carburant D > ES > H
     */
    private Integer choisirMeilleurVehiculeAvecFractionnement(
            List<Vehicule> candidats,
            Map<Integer, Integer> placesRestantes,
            int nbPassagers,
            Map<Integer, Integer> trajetsParVehicule) {

        if (candidats.isEmpty()) return null;

        // Séparer en 2 groupes : suffisants (places >= nbPassagers) et insuffisants
        List<Vehicule> suffisants = new ArrayList<>();
        List<Vehicule> insuffisants = new ArrayList<>();

        for (Vehicule v : candidats) {
            int places = placesRestantes.get(v.getId());
            if (places >= nbPassagers) {
                suffisants.add(v);
            } else {
                insuffisants.add(v);
            }
        }

        if (!suffisants.isEmpty()) {
            // Trier par places restantes ASC (le moins de places restantes en premier)
            return choisirMeilleurVehicule(suffisants, placesRestantes, trajetsParVehicule);
        } else {
            // Trier par places restantes DESC (le plus de places restantes en premier)
            trierParPlacesRestantesDesc(insuffisants, placesRestantes, trajetsParVehicule);
            return insuffisants.get(0).getId();
        }
    }

    /**
     * Parmi les candidats, choisit le meilleur véhicule.
     * Critères (dans l'ordre) :
     *   1. Moins de places restantes (plus petit qui convient) — EXISTANT
     *   2. Moins de trajets effectués dans la journée — NOUVEAU
     *   3. Priorité carburant : D > ES > H — ÉLARGI
     */
    private Integer choisirMeilleurVehicule(List<Vehicule> candidats, Map<Integer, Integer> placesRestantes, Map<Integer, Integer> trajetsParVehicule) {
        if (candidats.isEmpty()) return null;

        // Tri multi-critères (bubble sort)
        for (int i = 0; i < candidats.size() - 1; i++) {
            for (int j = 0; j < candidats.size() - i - 1; j++) {
                Vehicule v1 = candidats.get(j);
                Vehicule v2 = candidats.get(j + 1);
                int p1 = placesRestantes.get(v1.getId());
                int p2 = placesRestantes.get(v2.getId());

                boolean swap = false;
                if (p1 > p2) {
                    // 1. Moins de places restantes en premier
                    swap = true;
                } else if (p1 == p2) {
                    int t1 = trajetsParVehicule.getOrDefault(v1.getId(), 0);
                    int t2 = trajetsParVehicule.getOrDefault(v2.getId(), 0);
                    if (t1 > t2) {
                        // 2. Moins de trajets en premier
                        swap = true;
                    } else if (t1 == t2) {
                        // 3. Priorité carburant : D > ES > H
                        if (prioriteCarburant(v1.getTypeCarburant()) < prioriteCarburant(v2.getTypeCarburant())) {
                            swap = true;
                        }
                    }
                }

                if (swap) {
                    candidats.set(j, v2);
                    candidats.set(j + 1, v1);
                }
            }
        }

        return candidats.get(0).getId();
    }

    private int prioriteCarburant(String typeCarburant) {
        if ("D".equals(typeCarburant)) return 3;
        if ("ES".equals(typeCarburant)) return 2;
        if ("H".equals(typeCarburant)) return 1;
        return 0;
    }

    /** Trouve un véhicule dans la liste par son id */
    private Vehicule trouverVehiculeParId(List<Vehicule> vehicules, int id) {
        for (Vehicule v : vehicules) {
            if (v.getId() == id) return v;
        }
        return null;
    }

    /** Tri par nbPassager décroissant (bubble sort) */
    private void trierParNbPassagerDesc(List<Reservation> reservations) {
        for (int i = 0; i < reservations.size() - 1; i++) {
            for (int j = 0; j < reservations.size() - i - 1; j++) {
                if (reservations.get(j).getNbPassager() < reservations.get(j + 1).getNbPassager()) {
                    Reservation tmp = reservations.get(j);
                    reservations.set(j, reservations.get(j + 1));
                    reservations.set(j + 1, tmp);
                }
            }
        }
    }

    /**
     * Sprint 8: Tri avec priorité stricte aux réservations décalées.
     * 1) Décalées d'abord
     * 2) Puis ordre chronologique (dateArrivee ASC)
     * 3) Puis nbPassager DESC (tie-break)
     */
    private void trierAvecPrioriteDecalees(List<Reservation> reservations) {
        for (int i = 0; i < reservations.size() - 1; i++) {
            for (int j = 0; j < reservations.size() - i - 1; j++) {
                Reservation r1 = reservations.get(j);
                Reservation r2 = reservations.get(j + 1);

                boolean swap = false;

                if (!r1.isDecalee() && r2.isDecalee()) {
                    swap = true;
                } else if (r1.isDecalee() == r2.isDecalee()) {
                    String d1 = r1.getDateArrivee();
                    String d2 = r2.getDateArrivee();
                    if (d1 != null && d2 != null) {
                        if (d1.compareTo(d2) > 0) {
                            swap = true;
                        } else if (d1.compareTo(d2) == 0) {
                            if (r1.getNbPassager() < r2.getNbPassager()) {
                                swap = true;
                            }
                        }
                    } else {
                        // fallback : trier par nbPassager DESC
                        if (r1.getNbPassager() < r2.getNbPassager()) {
                            swap = true;
                        }
                    }
                }

                if (swap) {
                    reservations.set(j, r2);
                    reservations.set(j + 1, r1);
                }
            }
        }
    }

    /** Ajoute des minutes à un timestamp au format "yyyy-MM-dd HH:mm:ss" */
    private String ajouterMinutes(String timestamp, int minutes) {
        long ms = java.sql.Timestamp.valueOf(timestamp).getTime();
        ms += (long) minutes * 60 * 1000;
        return new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
            .format(new java.util.Date(ms));
    }
}

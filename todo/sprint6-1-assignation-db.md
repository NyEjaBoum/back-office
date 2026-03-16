# DEV 3383 — SPRINT 6 : BASE DE DONNÉES, MODÈLES & DAO ASSIGNATION

## Objectif

Préparer la couche **données** pour la nouvelle logique d'assignation des véhicules :
schéma DB, modèle Java `Assignation`, et DAO de persistance.

---

## 1. Modifier la table `assignation`

La table `assignation` existe déjà (`script/20260223/db_20260223_assignation.sql`) mais elle n'est **pas dans le script Sprint 5** (`script/20260311/db_20260311_sprint5.sql`).

Il faut la recréer pour supporter le Sprint 6. La table est simple : elle stocke uniquement le **lien véhicule-réservation** et le flag **décalée**. Toutes les autres infos (heure de départ, heure de retour, distance) sont calculées en mémoire pendant le traitement.

```sql
CREATE TABLE assignation (
    id SERIAL PRIMARY KEY,
    idVehicule INTEGER NOT NULL REFERENCES vehicule(id),
    idReservation INTEGER NOT NULL REFERENCES reservation(id),
    decalee BOOLEAN NOT NULL DEFAULT FALSE, -- true si la réservation a été traitée en décalage
    datePlanification TIMESTAMP NOT NULL DEFAULT NOW()
);
```

> **decalee = true** quand la réservation n'a pas trouvé de véhicule dans son groupe d'origine
> et a été reportée à un groupe horaire ultérieur.
> Exemple : R4 (arrivée 08:08, groupe 08:00-08:30) → aucun véhicule → reportée au groupe 10:00-10:30 → `decalee = true`.
> Utilisé en UI pour afficher un tag "DÉCALÉE" sur ces réservations.
>
> **datePlanification** garde une trace de quand la génération a été lancée (historique/debug).

A créer dans les 3 schémas : `dev`, `staging`, `prod`

---

## 2. Créer le script de migration

Créer le fichier : `script/20260316/db_20260316_sprint6.sql`

Ce script doit :

- [ ] Ajouter la table `assignation` (avec les nouvelles colonnes) dans les 3 schémas
- [ ] Accorder les droits aux rôles (`app_dev`, `app_staging`, `app_prod`)

---

## 3. Mettre à jour `reset.sql`

- [ ] Vérifier que `TRUNCATE assignation RESTART IDENTITY CASCADE` est présent et cohérent
- [ ] S'assurer que le TRUNCATE est dans le bon ordre (assignation avant reservation car FK)

---

## 4. Créer le modèle `Assignation.java`

Fichier : `src/main/java/model/Assignation.java` (nouveau fichier)

```java
package model;

public class Assignation {
    private int id;
    private int idVehicule;
    private int idReservation;
    private boolean decalee;            // true si traitée en décalage horaire
    private String datePlanification;   // format TIMESTAMP

    // Constructeurs, getters, setters, toString
}
```

> Le champ `decalee` est utilisé par le DEV 3383 pour afficher un tag "DÉCALÉE" en UI.
> Il est `true` quand l'heure de départ effective du groupe > `reservation.dateArrivee`.

---

## 5. Créer `AssignationDao.java`

Fichier : `src/main/java/dao/AssignationDao.java` (nouveau fichier)

Ce DAO doit fournir les méthodes suivantes :

### 5.1 Supprimer les assignations des réservations d'une date

```java
/**
 * Supprime toutes les assignations liées aux réservations d'une date donnée.
 * Appelé au début de chaque génération.
 */
public void supprimerParDate(String date) throws SQLException {
    String sql = "DELETE FROM assignation a USING reservation r "
               + "WHERE a.idReservation = r.id AND DATE(r.dateArrivee) = ?";
    // ...
}
```

- [ ] Implémenter cette méthode

### 5.2 Insérer une assignation

```java
/**
 * Insère une nouvelle assignation en base.
 */
public void insert(Assignation assignation) throws SQLException {
    String sql = "INSERT INTO assignation (idVehicule, idReservation, decalee) VALUES (?, ?, ?)";
    // ...
}
```

- [ ] Implémenter cette méthode

### 5.3 Récupérer les assignations des réservations d'une date

```java
/**
 * Retourne toutes les assignations liées aux réservations d'une date donnée.
 */
public List<Assignation> findByDate(String date) throws SQLException {
    String sql = "SELECT a.* FROM assignation a "
               + "JOIN reservation r ON a.idReservation = r.id "
               + "WHERE DATE(r.dateArrivee) = ?";
    // ...
}
```

- [ ] Implémenter cette méthode

---

## Résumé des fichiers à créer/modifier (DEV 3389)

| Fichier                                   | Action                                        |
|-------------------------------------------|-----------------------------------------------|
| `script/20260316/db_20260316_sprint6.sql` | **Créer** — migration table assignation       |
| `reset.sql`                               | **Vérifier** — cohérence TRUNCATE assignation |
| `src/main/java/model/Assignation.java`    | **Créer** — nouveau modèle                    |
| `src/main/java/dao/AssignationDao.java`   | **Créer** — CRUD assignation                  |

> **Pas de modification sur `Reservation.java` ni `ReservationDao.java`**.
> Le backend traite toute la journée d'un coup en mémoire. Pour savoir si une réservation est assignée,
> il suffit de vérifier si elle a une ligne dans la table `assignation`.

---

## Dépendances

> **Le DEV 3389 (algorithme) dépend de ton travail.**
> Il aura besoin de `AssignationDao` et du modèle `Assignation` pour implémenter la logique d'assignation.
> Essaie de livrer en priorité : le script SQL, le modèle, et le DAO.

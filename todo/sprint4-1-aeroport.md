# DEV 3389 — SCRIPTS & BASE DE DONNÉES

## Ajout de la table `type_lieu`

### Objectif
Actuellement, le code cherche l'aéroport avec le code `AERO` en dur.
Il faut pouvoir gérer plusieurs aéroports et distinguer les types de lieux (Aéroport, Hôtel, etc.)

---

### 1. Créer la table `type_lieu`

Ajouter dans le script SQL (`nyeja.txt` / script d'init) :

```sql
CREATE TABLE type_lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,  -- ex: 'AEROPORT', 'HOTEL'
    libelle VARCHAR(255) NOT NULL       -- ex: 'Aéroport', 'Hôtel'
);
```

À créer dans les 3 schémas : `dev`, `staging`, `prod`

---

### 2. Modifier la table `lieu`

Ajouter une colonne `idTypeLieu` qui référence `type_lieu` :

```sql
ALTER TABLE lieu ADD COLUMN idTypeLieu INTEGER REFERENCES type_lieu(id);
```

À appliquer dans les 3 schémas : `dev`, `staging`, `prod`

---

### 3. Mettre à jour `reset.sql`

Insérer les types de lieux et mettre à jour les lieux existants :

```sql
-- Insérer les types
INSERT INTO dev.type_lieu (code, libelle) VALUES
    ('AEROPORT', 'Aéroport'),
    ('HOTEL', 'Hôtel');

-- Mettre à jour les lieux existants
UPDATE dev.lieu SET idTypeLieu = (SELECT id FROM dev.type_lieu WHERE code = 'AEROPORT')
    WHERE code = 'AERO';

UPDATE dev.lieu SET idTypeLieu = (SELECT id FROM dev.type_lieu WHERE code = 'HOTEL')
    WHERE code IN ('COLB', 'NOVO', 'IBIS', 'LOKA', 'CARL');
```

À faire aussi pour `staging` et `prod`

---

### 4. Créer le script de migration

Créer le fichier :
`script/20260304/db_20260304_type_lieu.sql`

Ce script doit :
- [ ] Créer la table `type_lieu` dans les 3 schémas
- [ ] Ajouter la colonne `idTypeLieu` dans `lieu`
- [ ] Insérer les types (`AEROPORT`, `HOTEL`)
- [ ] Mettre à jour les données existantes

---

### 5. Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `reset.sql` | Ajouter `TRUNCATE type_lieu`, insérer types, mettre à jour lieux |
| `nyeja.txt` | Ajouter `CREATE TABLE type_lieu` dans les 3 schémas |
| `script/20260304/db_20260304_type_lieu.sql` | Nouveau fichier de migration |

---

### 6. Modifier le modèle `Lieu.java`

Fichier : `src/main/java/model/Lieu.java`

- [ ] Ajouter le champ `idTypeLieu` (int)
- [ ] Ajouter getters/setters
- [ ] Mettre à jour `toString()`

```java
private int idTypeLieu;
public int getIdTypeLieu() { return idTypeLieu; }
public void setIdTypeLieu(int idTypeLieu) { this.idTypeLieu = idTypeLieu; }
```

---

### 7. Modifier `LieuDao.java`

Fichier : `src/main/java/dao/LieuDao.java`

- [ ] Mettre à jour `findAll()` pour inclure `idTypeLieu`
- [ ] Mettre à jour `findById()` pour inclure `idTypeLieu`
- [ ] Mettre à jour `findByCode()` pour inclure `idTypeLieu`
- [ ] Ajouter une méthode `findByType(String codeType)` :

```java
/**
 * Retourne tous les lieux d'un type donné (ex: 'AEROPORT', 'HOTEL')
 */
public List<Lieu> findByType(String codeType) throws SQLException {
    String sql = "SELECT l.id, l.code, l.libelle, l.idTypeLieu " +
                 "FROM lieu l " +
                 "JOIN type_lieu t ON l.idTypeLieu = t.id " +
                 "WHERE t.code = ?";
    // ...
}
```

---

### 8. Modifier `PlanningDao.java`

Fichier : `src/main/java/dao/PlanningDao.java`

- [ ] Remplacer `getIdAeroport()` qui cherche par code `AERO` en dur
- [ ] Nouvelle méthode `getIdAeroports()` qui retourne **tous** les aéroports

```java
/**
 * Retourne la liste de tous les lieux de type AEROPORT
 */
private List<Integer> getIdAeroports() throws Exception {
    LieuDao lieuDao = new LieuDao();
    List<Lieu> aeroports = lieuDao.findByType("AEROPORT");
    if (aeroports.isEmpty()) throw new Exception("Aucun lieu de type AEROPORT trouvé en base");
    List<Integer> ids = new ArrayList<>();
    for (Lieu l : aeroports) ids.add(l.getId());
    return ids;
}
```

- [ ] Mettre à jour `calculerDistanceGreedy()` pour utiliser `getIdAeroports()` :
  - Choisir l'aéroport **le plus proche** des lieux de la réservation comme point de départ/retour

---

### Résumé des fichiers à modifier (DEV 3389)

| Fichier | Action |
|---------|--------|
| `reset.sql` | Ajouter type_lieu, mettre à jour lieu |
| `nyeja.txt` | Ajouter CREATE TABLE type_lieu |
| `script/20260304/db_20260304_type_lieu.sql` | Créer (nouveau) |
| `src/main/java/model/Lieu.java` | Ajouter idTypeLieu |
| `src/main/java/dao/LieuDao.java` | Ajouter findByType(), mettre à jour les autres méthodes |
| `src/main/java/dao/PlanningDao.java` | Remplacer getIdAeroport() par getIdAeroports() |
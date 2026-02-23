# DEV 3389 — SCRIPTS

## Script de suppression / réinitialisation dans `reset.sql`

## Création des tables

### Table `lieu`

- [ ] Créer la table `lieu` avec la structure suivante :

```sql
CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50),
    libelle VARCHAR(255)
);
```

### Table `parametre`

- [ ] Créer la table `parametre` avec la structure suivante :

```sql
CREATE TABLE parametre (
    id SERIAL PRIMARY KEY,
    vitesseMoyenne INTEGER NOT NULL,
    tempsAttente INTEGER NOT NULL
);
```

### Table `distance`

- [ ] Créer la table `distance` avec la structure suivante :

```sql
CREATE TABLE distance (
    id SERIAL PRIMARY KEY,
    "from" INTEGER REFERENCES lieu(id),
    "to" INTEGER REFERENCES lieu(id),
    km NUMERIC NOT NULL
);
```

> **Règle métier :** Une seule ligne par paire de lieux (la distance aller est identique au retour).

## Modification de la table `reservation`

- [ ] Remplacer la colonne `idHotel` par la nouvelle colonne `idLieu` dans la table `reservation`
- [ ] Supprimer la table `hotel`

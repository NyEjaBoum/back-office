# DEV 3657 — BACK OFFICE AMÉLIORATIONS

## 1. Tri alphabétique des hôtels dans le trajet (priorité si même distance)

### Objectif
Dans l'algorithme Greedy, quand deux lieux ont la **même distance**, le lieu dont
le **nom est alphabétiquement le plus petit** doit être visité en premier.

### Fichier à modifier
`src/main/java/dao/PlanningDao.java`

### Changement dans `calculerDistanceGreedy()`
- [ ] Lors du choix du prochain lieu (nearest neighbor), si deux lieux ont la même distance :
  - Comparer les noms (`nomLieu`) alphabétiquement
  - Prendre celui qui vient en premier dans l'ordre alphabétique

```java
// Exemple de logique à ajouter dans la boucle greedy :
// Si dist == minDist et nomLieu < nomLieuActuel → prendre ce lieu
if (dist < minDist || (dist == minDist && nomLieu.compareTo(nomLieuMin) < 0)) {
    minDist = dist;
    next = l;
    nomLieuMin = nomLieu;
}
```

> ⚠️ Pour récupérer le nom du lieu, il faudra faire un `JOIN` ou une map `idLieu -> nomLieu`
> préparée avant la boucle.

---

## 2. Affichage de la distance du trajet dans la page de planification

### Objectif
Afficher la distance totale du trajet (en km) dans le tableau des véhicules planifiés.

### Fichiers à modifier

**`src/main/webapp/WEB-INF/views/planningResult.jsp`**
- [ ] Ajouter une colonne `Distance` dans le tableau des véhicules planifiés :

```jsp
<th>Distance</th>
<!-- Dans la boucle : -->
<td><%= ligne.get("distanceTotale") %> km</td>
```

**`src/main/java/dao/PlanningDao.java`**
- [ ] Vérifier que `distanceTotale` est bien dans la Map retournée (déjà fait ✅)

---

## 3. Filtre par date dans la liste des réservations

### Objectif
Permettre à l'utilisateur de filtrer les réservations par date dans la page liste.

### Fichiers à modifier

**`src/main/webapp/WEB-INF/views/reservationList.jsp`**
- [ ] Ajouter un formulaire de filtre en haut de la page :

```jsp
<form method="get" action="${pageContext.request.contextPath}/reservations">
    <input type="date" name="date" value="${param.date}">
    <button type="submit" class="btn btn-secondary">Filtrer</button>
    <a href="${pageContext.request.contextPath}/reservations" class="btn btn-secondary">Tout afficher</a>
</form>
```

**`src/main/java/controller/ReservationController.java`**
- [ ] Modifier `listReservationsView()` pour accepter le paramètre `date` :

```java
@Get("/reservations")
public ModelView listReservationsView(HttpServletRequest request) {
    String date = request.getParameter("date"); // null si pas de filtre
    List<Reservation> reservations;
    if (date != null && !date.isEmpty()) {
        reservations = reservationDao.findByDate(date); // déjà existant
    } else {
        reservations = reservationDao.findAll();
    }
    mv.addData("reservations", reservations);
    mv.addData("dateFiltre", date); // pour pré-remplir le champ date
}
```

**`src/main/java/dao/ReservationDao.java`**
- [ ] `findByDate()` existe déjà ✅, pas de modification nécessaire

---

## Résumé des fichiers à modifier (DEV 3657)

| Fichier | Action |
|---------|--------|
| `src/main/java/dao/PlanningDao.java` | Tri alphabétique si même distance dans greedy |
| `src/main/webapp/WEB-INF/views/planningResult.jsp` | Ajouter colonne Distance |
| `src/main/webapp/WEB-INF/views/reservationList.jsp` | Ajouter formulaire filtre par date |
| `src/main/java/controller/ReservationController.java` | Gérer paramètre `date` dans `listReservationsView()` |

---

## Ordre de développement recommandé

1. ✅ **DEV 3389** d'abord (base de données) — sprint4-1
   - La table `type_lieu` est nécessaire avant les développements BO
2. Ensuite **DEV 3657** (sprint4-2)
   - Les features sont indépendantes entre elles et peuvent être faites en parallèle
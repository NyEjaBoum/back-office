<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="model.Reservation" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultat planification</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar" style="position: relative;">
        <span class="nav-brand">Back Office</span>
        <%-- <span class="nav-brand">ETU003383    ETU003389   ETU3657</span> --%>
        <p class="text-muted" style="position: absolute; left: 50%; transform: translateX(-50%); margin: 0; font-size: 3rem; font-weight: 800; line-height: 1; white-space: nowrap;">ETU003383 - ETU003389 - ETU003657</p>
        <a href="${pageContext.request.contextPath}/reservations">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning" class="active">Planning</a>
    </nav>

    <div class="page">
        <div class="card">
            <div class="flex-between mb-16">
                <h1 class="page-title" style="margin-bottom:0">Planification du <%= request.getAttribute("date") %></h1>
                <a href="${pageContext.request.contextPath}/planning" class="btn btn-secondary">Nouvelle date</a>
            </div>

            <% String error = (String) request.getAttribute("error"); %>
            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-error"><%= error %></div>
            <% } %>

            <!-- Tableau 1 : Vehicules planifies -->
            <h2 class="section-title">Vehicules planifies</h2>
            <%
                List<Map<String, Object>> vehiculesPlanifies = (List<Map<String, Object>>) request.getAttribute("vehiculesPlanifies");
                if (vehiculesPlanifies == null || vehiculesPlanifies.isEmpty()) {
            %>
                <div class="empty-state">Aucun vehicule planifie.</div>
            <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Vehicule</th>
                        <th>Reservations assignees</th>
                        <th>Ordre du trajet</th>
                        <th>Distance</th>
                        <th>Depart</th>
                        <th>Retour</th>
                    </tr>
                </thead>
                <tbody>
                <% String currentGroupe = "";
                   int groupeIndex = 0;
                   String[] groupeColors = {"#eff6ff", "#f0fdf4", "#fdf4ff", "#fef3c7", "#fdf2f8", "#ecfdf5", "#fff7ed"};
                   for (Map<String, Object> ligne : vehiculesPlanifies) {
                    Vehicule v = (Vehicule) ligne.get("vehicule");
                    String groupeHeure = (String) ligne.get("groupeHeure");
                    boolean newGroupe = !groupeHeure.equals(currentGroupe);
                    if (newGroupe) {
                        if (!currentGroupe.isEmpty()) { groupeIndex++; }
                        currentGroupe = groupeHeure;
                    }
                    String bgColor = groupeColors[groupeIndex % groupeColors.length];
                %>
                    <% if (newGroupe) { %>
                    <tr class="groupe-header">
                        <td colspan="6">
                            <span class="groupe-label">Groupe <%= groupeHeure.substring(11) %></span>
                        </td>
                    </tr>
                    <% } %>
                    <tr style="background: <%= bgColor %>">
                        <td>
                            <strong><%= v.getReference() %></strong>
                            <br>
                            <span class="text-muted"><%= v.getNbrPlace() %> places &middot;
                                <%= "D".equals(v.getTypeCarburant()) ? "Diesel" : "ES".equals(v.getTypeCarburant()) ? "Essence" : "Hybride" %>
                            </span>
                        </td>
                        <td>
                            <% java.util.List<java.util.Map<String, Object>> detailsFractions = (java.util.List<java.util.Map<String, Object>>) ligne.get("detailsFractions");
                               java.util.Set<Integer> reservationsDejaTaitees = new java.util.HashSet<>();

                               if (detailsFractions != null) {
                                   for (java.util.Map<String, Object> fraction : detailsFractions) {
                                       Integer idRes = (Integer) fraction.get("id");
                                       if (!reservationsDejaTaitees.contains(idRes)) {
                                           String nomLieu = (String) fraction.get("nomLieu");
                                           String idClient = (String) fraction.get("idClient");
                                           int nbAffecte = (Integer) fraction.get("nbPassagerAffecte");
                                           int nbOriginal = (Integer) fraction.get("nbPassagerOriginal");
                                           String dateArrivee = (String) fraction.get("dateArrivee");
                                           boolean decalee = (Boolean) fraction.get("decalee");
                            %>
                                <div class="reservation-item">
                                    <span class="badge">R#<%= idRes %></span>
                                    <span class="badge">C#<%= idClient %></span>
                                    <span class="badge badge-blue"><%= nomLieu %></span>
                                    <span class="badge badge-purple"><%= nbAffecte %> pass.</span>
                                    <span class="text-muted"><%= dateArrivee.substring(11) %></span>
                                    <% if (nbAffecte < nbOriginal) { %>
                                        <span class="badge badge-warning">Fraction</span>
                                    <% } %>
                                    <% if (decalee) { %>
                                        <span class="badge badge-warning">DECALEE</span>
                                    <% } %>
                                </div>
                            <%
                                           reservationsDejaTaitees.add(idRes);
                                       }
                                   }
                               }
                            %>
                        </td>
                        <td>
                            <% List<String> ordreTrajet = (List<String>) ligne.get("ordreTrajet");
                               if (ordreTrajet != null && !ordreTrajet.isEmpty()) { %>
                                Aeroport
                                <% for (String nomLieu : ordreTrajet) { %>
                                    &rarr; <span class="badge badge-blue"><%= nomLieu %></span>
                                <% } %>
                                &rarr; Aeroport
                            <% } else { %>
                                <span class="text-muted">-</span>
                            <% } %>
                        </td>
                        <td><%= String.format("%.1f", ligne.get("distanceTotale")) %> km</td>
                        <td><%= ligne.get("heureDepart").toString().substring(11) %></td>
                        <td><%= ligne.get("heureRetour").toString().substring(11) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>

            <!-- Tableau 2 : Reservations non assignees -->
            <h2 class="section-title mt-32">Reservations non assignees</h2>
            <%
                List<Reservation> reservationsNonAssignees = (List<Reservation>) request.getAttribute("reservationsNonAssignees");
                if (reservationsNonAssignees == null || reservationsNonAssignees.isEmpty()) {
            %>
                <div class="empty-state">Toutes les reservations ont ete assignees.</div>
            <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Client</th>
                        <th>Passagers</th>
                        <th>Lieu</th>
                        <th>Date arrivee</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Reservation r : reservationsNonAssignees) { %>
                    <tr>
                        <td class="text-muted">#<%= r.getId() %></td>
                        <td><%= r.getIdClient() %></td>
                        <td><%= r.getNbPassager() %></td>
                        <td><span class="badge badge-blue"><%= r.getNomLieu() %></span></td>
                        <td><%= r.getDateArrivee().substring(11) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>
        </div>
    </div>
</body>
</html>

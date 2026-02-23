<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="model.Reservation" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <title>Résultat de la planification</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        body {
            background: #f4f6fb;
        }
        .container {
            max-width: 700px;
            margin: 40px auto;
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 4px 24px rgba(0,0,0,0.07);
            padding: 32px 40px 40px 40px;
        }
        h2 {
            text-align: center;
            color: #222;
            margin-bottom: 18px;
        }
        h3 {
            margin-top: 36px;
            color: #444;
            font-size: 1.2em;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            background: #fff;
            margin-bottom: 32px;
        }
        th, td {
            padding: 12px 10px;
            text-align: left;
        }
        th {
            background: #667eea;
            color: #fff;
            font-weight: 600;
            font-size: 14px;
        }
        tr:nth-child(even) {
            background: #f7f8fa;
        }
        .badge-lieu {
            background: #e3f2fd;
            color: #1976d2;
            border-radius: 12px;
            padding: 2px 10px;
            font-size: 12px;
            margin-right: 4px;
        }
        .badge-passager {
            background: #f3e5f5;
            color: #7b1fa2;
            border-radius: 12px;
            padding: 2px 10px;
            font-size: 12px;
            margin-left: 4px;
        }
        .vehicule-label {
            font-weight: bold;
            color: #333;
        }
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
            border-radius: 6px;
            padding: 10px 16px;
            margin-bottom: 18px;
            text-align: center;
        }
        .no-data {
            color: #888;
            text-align: center;
            padding: 18px 0;
        }
    </style>
</head>
<body>
<div class="container">
    <h2>Résultat de la planification pour la date : <span style="color:#667eea;"><%= request.getAttribute("date") %></span></h2>
    <% String error = (String) request.getAttribute("error"); %>
    <% if (error != null && !error.isEmpty()) { %>
        <div class="error"><%= error %></div>
    <% } %>

    <h3>Tableau 1 — Véhicules planifiés</h3>
    <%
        List<Map<String, Object>> vehiculesPlanifies = (List<Map<String, Object>>) request.getAttribute("vehiculesPlanifies");
        if (vehiculesPlanifies == null || vehiculesPlanifies.isEmpty()) {
    %>
        <div class="no-data">Aucun véhicule planifié.</div>
    <%
        } else {
    %>
        <table>
            <thead>
                <tr>
                    <th>Véhicule</th>
                    <th>Réservations assignées</th>
                    <th>Heure départ</th>
                    <th>Heure retour</th>
                </tr>
            </thead>
            <tbody>
            <% for (Map<String, Object> ligne : vehiculesPlanifies) { %>
                <tr>
                    <td class="vehicule-label"><%= ((Vehicule)ligne.get("vehicule")).getReference() %> <br>
                        <span style="font-size:12px;color:#888;">
                            <%= ((Vehicule)ligne.get("vehicule")).getNbrPlace() %> places, <%= ((Vehicule)ligne.get("vehicule")).getTypeCarburant() %>
                        </span>
                    </td>
                    <td>
                        <% List<Reservation> groupe = (List<Reservation>) ligne.get("reservations");
                           for (Reservation r : groupe) { %>
                            <div>
                                <span class="badge-lieu"><%= r.getNomLieu() %></span>
                                <span class="badge-passager"><%= r.getNbPassager() %> 👤</span>
                                <span style="color:#888;font-size:12px;">[<%= r.getDateArrivee() %>]</span>
                            </div>
                        <% } %>
                    </td>
                    <td><%= ligne.get("heureDepart") %></td>
                    <td><%= ligne.get("heureRetour") %></td>
                </tr>
            <% } %>
            </tbody>
        </table>
    <%
        }
    %>

    <h3>Tableau 2 — Réservations non assignées</h3>
    <%
        List<Reservation> reservationsNonAssignees = (List<Reservation>) request.getAttribute("reservationsNonAssignees");
        if (reservationsNonAssignees == null || reservationsNonAssignees.isEmpty()) {
    %>
        <div class="no-data">Toutes les réservations ont été assignées à un véhicule.</div>
    <%
        } else {
    %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Nb Passagers</th>
                    <th>Lieu</th>
                    <th>Date arrivée</th>
                </tr>
            </thead>
            <tbody>
            <% for (Reservation r : reservationsNonAssignees) { %>
                <tr>
                    <td><%= r.getId() %></td>
                    <td><%= r.getIdClient() %></td>
                    <td><%= r.getNbPassager() %></td>
                    <td><span class="badge-lieu"><%= r.getNomLieu() %></span></td>
                    <td><%= r.getDateArrivee() %></td>
                </tr>
            <% } %>
            </tbody>
        </table>
    <%
        }
    %>
</div>
</body>
</html>
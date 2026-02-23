<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Reservation" %>
<%@ page import="java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reservations</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar">
        <span class="nav-brand">Back Office</span>
        <a href="${pageContext.request.contextPath}/reservations" class="active">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning">Planning</a>
    </nav>

    <div class="page">
        <div class="card">
            <div class="flex-between mb-16">
                <h1 class="page-title" style="margin-bottom:0">Reservations</h1>
                <a href="${pageContext.request.contextPath}/reservations/add" class="btn btn-primary">Nouvelle reservation</a>
            </div>

            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error"><%= request.getAttribute("error") %></div>
            <% } %>

            <%
                List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");

                if (reservations == null || reservations.isEmpty()) {
            %>
                <div class="empty-state">Aucune reservation trouvee.</div>
            <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Client</th>
                        <th>Passagers</th>
                        <th>Lieu</th>
                        <th>Date d'arrivee</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Reservation r : reservations) { %>
                    <tr>
                        <td class="text-muted">#<%= r.getId() %></td>
                        <td><span class="badge badge-purple"><%= r.getIdClient() %></span></td>
                        <td><%= r.getNbPassager() %></td>
                        <td><span class="badge badge-blue"><%= r.getNomLieu() %></span></td>
                        <td><%= sdf.format(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse(r.getDateArrivee())) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>
        </div>
    </div>
</body>
</html>

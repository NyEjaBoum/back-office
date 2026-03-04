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
                String dateFiltre = (String) request.getAttribute("dateFiltre");
                String triFiltre = (String) request.getAttribute("triFiltre");
                if (dateFiltre == null) dateFiltre = "";
                if (triFiltre == null) triFiltre = "";
            %>
            <form method="get" action="${pageContext.request.contextPath}/reservations" style="display:flex;gap:12px;align-items:flex-end;margin-bottom:16px;flex-wrap:wrap">
                <div>
                    <label class="text-muted" style="display:block;font-size:0.85em;margin-bottom:4px">Date</label>
                    <input type="date" name="date" value="<%= dateFiltre %>" class="form-control">
                </div>
                <div>
                    <label class="text-muted" style="display:block;font-size:0.85em;margin-bottom:4px">Trier par</label>
                    <select name="tri" class="form-control">
                        <option value="" <%= "".equals(triFiltre) ? "selected" : "" %>>Date (recent d'abord)</option>
                        <option value="dateAsc" <%= "dateAsc".equals(triFiltre) ? "selected" : "" %>>Date (ancien d'abord)</option>
                        <option value="nom" <%= "nom".equals(triFiltre) ? "selected" : "" %>>Nom du lieu (A-Z)</option>
                        <option value="passagers" <%= "passagers".equals(triFiltre) ? "selected" : "" %>>Passagers (decroissant)</option>
                    </select>
                </div>
                <div style="display:flex;gap:8px">
                    <button type="submit" class="btn btn-secondary">Filtrer</button>
                    <a href="${pageContext.request.contextPath}/reservations" class="btn btn-secondary">Reinitialiser</a>
                </div>
            </form>

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

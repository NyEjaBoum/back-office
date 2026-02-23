<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vehicules</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar">
        <span class="nav-brand">Back Office</span>
        <a href="${pageContext.request.contextPath}/reservations">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules" class="active">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning">Planning</a>
    </nav>

    <div class="page">
        <div class="card">
            <div class="flex-between mb-16">
                <h1 class="page-title" style="margin-bottom:0">Vehicules</h1>
                <a href="${pageContext.request.contextPath}/vehicules/add" class="btn btn-primary">Ajouter</a>
            </div>

            <%
                String error = (String) request.getAttribute("error");
                String success = (String) request.getAttribute("success");
                if (error != null) {
            %>
                <div class="alert alert-error"><%= error %></div>
            <% } else if (success != null) { %>
                <div class="alert alert-success"><%= success %></div>
            <% } %>

            <%
                List<Vehicule> vehicules = (List<Vehicule>) request.getAttribute("vehicules");
                if (vehicules != null && !vehicules.isEmpty()) {
            %>
            <table>
                <thead>
                    <tr>
                        <th>Reference</th>
                        <th>Places</th>
                        <th>Carburant</th>
                        <th style="text-align:right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Vehicule v : vehicules) { %>
                    <tr>
                        <td><strong><%= v.getReference() %></strong></td>
                        <td><%= v.getNbrPlace() %></td>
                        <td>
                            <span class="badge badge-blue">
                                <%= "D".equals(v.getTypeCarburant()) ? "Diesel" : "ES".equals(v.getTypeCarburant()) ? "Essence" : "Hybride" %>
                            </span>
                        </td>
                        <td style="text-align:right">
                            <div class="actions" style="justify-content:flex-end">
                                <a href="${pageContext.request.contextPath}/vehicules/edit?id=<%= v.getId() %>" class="btn btn-secondary btn-sm">Modifier</a>
                                <form action="${pageContext.request.contextPath}/vehicules/delete" method="post" class="inline-form">
                                    <input type="hidden" name="id" value="<%= v.getId() %>"/>
                                    <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Supprimer ce vehicule ?');">Supprimer</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <% } else { %>
                <div class="empty-state">Aucun vehicule trouve.</div>
            <% } %>
        </div>
    </div>
</body>
</html>

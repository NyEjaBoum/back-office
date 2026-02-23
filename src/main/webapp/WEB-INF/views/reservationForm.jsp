<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Lieu" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nouvelle reservation</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar">
        <span class="nav-brand">Back Office</span>
        <a href="${pageContext.request.contextPath}/reservations" class="active">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning">Planning</a>
    </nav>

    <div class="page page--narrow">
        <div class="card">
            <h1 class="page-title">Nouvelle reservation</h1>

            <% if (request.getAttribute("success") != null) { %>
                <div class="alert alert-success"><%= request.getAttribute("success") %></div>
            <% } %>
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error"><%= request.getAttribute("error") %></div>
            <% } %>

            <form action="${pageContext.request.contextPath}/reservations/add" method="POST">
                <div class="form-group">
                    <label for="clientId">ID Client</label>
                    <input type="text" id="clientId" name="clientId" pattern="\d{4}" maxlength="4" placeholder="1234" required>
                    <p class="form-hint">Exactement 4 chiffres</p>
                </div>

                <div class="form-group">
                    <label for="nbPassager">Nombre de passagers</label>
                    <input type="number" id="nbPassager" name="nbPassager" min="1" max="100" placeholder="2" required>
                </div>

                <div class="form-group">
                    <label for="dateHeureArrivee">Date et heure d'arrivee</label>
                    <input type="datetime-local" id="dateHeureArrivee" name="dateHeureArrivee" required>
                </div>

                <div class="form-group">
                    <label for="idLieu">Lieu</label>
                    <select id="idLieu" name="idLieu" required>
                        <option value="">-- Selectionner --</option>
                        <%
                            List<Lieu> lieux = (List<Lieu>) request.getAttribute("lieux");
                            if (lieux != null) {
                                for (Lieu lieu : lieux) {
                        %>
                            <option value="<%= lieu.getId() %>"><%= lieu.getLibelle() %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                </div>

                <div class="mt-24">
                    <button type="submit" class="btn btn-primary">Ajouter</button>
                    <a href="${pageContext.request.contextPath}/reservations" class="btn btn-secondary" style="margin-left:8px">Annuler</a>
                </div>
            </form>
        </div>
    </div>
</body>
</html>

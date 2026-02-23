<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vehicule</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar">
        <span class="nav-brand">Back Office</span>
        <a href="${pageContext.request.contextPath}/reservations">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules" class="active">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning">Planning</a>
    </nav>

    <div class="page page--narrow">
        <div class="card">
            <%
                Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
                String error = (String) request.getAttribute("error");
                String success = (String) request.getAttribute("success");
                boolean isEdit = vehicule != null && vehicule.getId() > 0;
            %>

            <h1 class="page-title"><%= isEdit ? "Modifier le vehicule" : "Nouveau vehicule" %></h1>

            <% if (error != null) { %>
                <div class="alert alert-error"><%= error %></div>
            <% } else if (success != null) { %>
                <div class="alert alert-success"><%= success %></div>
            <% } %>

            <form action="${pageContext.request.contextPath}/vehicules/<%= isEdit ? "update" : "add" %>" method="post">
                <% if (isEdit) { %>
                    <input type="hidden" name="id" value="<%= vehicule.getId() %>"/>
                <% } %>

                <div class="form-group">
                    <label for="reference">Reference</label>
                    <input type="text" id="reference" name="reference" value="<%= vehicule != null ? vehicule.getReference() : "" %>" required/>
                </div>

                <div class="form-group">
                    <label for="nbrPlace">Nombre de places</label>
                    <input type="number" id="nbrPlace" name="nbrPlace" min="1" value="<%= vehicule != null ? vehicule.getNbrPlace() : "" %>" required/>
                </div>

                <div class="form-group">
                    <label for="typeCarburant">Type de carburant</label>
                    <select id="typeCarburant" name="typeCarburant" required>
                        <option value="">-- Choisir --</option>
                        <option value="D" <%= vehicule != null && "D".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Diesel</option>
                        <option value="ES" <%= vehicule != null && "ES".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Essence</option>
                        <option value="H" <%= vehicule != null && "H".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Hybride</option>
                    </select>
                </div>

                <div class="mt-24">
                    <button type="submit" class="btn btn-primary"><%= isEdit ? "Mettre a jour" : "Ajouter" %></button>
                    <a href="${pageContext.request.contextPath}/vehicules" class="btn btn-secondary" style="margin-left:8px">Annuler</a>
                </div>
            </form>
        </div>
    </div>
</body>
</html>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <title>Formulaire Véhicule</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="container">
    <h2>Ajouter / Modifier un Véhicule</h2>
    <%
        Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
        String error = (String) request.getAttribute("error");
        String success = (String) request.getAttribute("success");
        boolean isEdit = vehicule != null && vehicule.getId() > 0;
    %>
    <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } else if (success != null) { %>
        <div class="alert alert-success"><%= success %></div>
    <% } %>
    <form action="${pageContext.request.contextPath}/vehicules/<%= isEdit ? "update" : "add" %>" method="post">
        <% if (isEdit) { %>
            <input type="hidden" name="id" value="<%= vehicule.getId() %>"/>
        <% } %>
        <label>Référence</label>
        <input type="text" name="reference" value="<%= vehicule != null ? vehicule.getReference() : "" %>" required/>
        <label>Nombre de places</label>
        <input type="number" name="nbrPlace" min="1" value="<%= vehicule != null ? vehicule.getNbrPlace() : "" %>" required/>
        <label>Type de carburant</label>
        <select name="typeCarburant" required>
            <option value="">--Choisir--</option>
            <option value="D" <%= vehicule != null && "D".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Diesel</option>
            <option value="ES" <%= vehicule != null && "ES".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Essence</option>
            <option value="H" <%= vehicule != null && "H".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Hybride</option>
        </select>
        <input type="submit" value="<%= isEdit ? "Mettre à jour" : "Ajouter" %>"/>
    </form>
    <a href="${pageContext.request.contextPath}/vehicules">Retour à la liste</a>
</div>
</body>
</html>
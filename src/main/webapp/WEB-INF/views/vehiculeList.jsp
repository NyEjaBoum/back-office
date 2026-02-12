<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <title>Liste des Véhicules</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="container">
    <h2>Liste des Véhicules</h2>
    <a href="${pageContext.request.contextPath}/vehicules/add" class="btn">Ajouter un véhicule</a>
    <%
        List<Vehicule> vehicules = (List<Vehicule>) request.getAttribute("vehicules");
        String error = (String) request.getAttribute("error");
        String success = (String) request.getAttribute("success");
        if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
    <% } else if (success != null) { %>
            <div class="alert alert-success"><%= success %></div>
    <% }
        if (vehicules != null && !vehicules.isEmpty()) { %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Référence</th>
                    <th>Places</th>
                    <th>Carburant</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <% for (Vehicule v : vehicules) { %>
                <tr>
                    <td><%= v.getId() %></td>
                    <td><%= v.getReference() %></td>
                    <td><%= v.getNbrPlace() %></td>
                    <td><%= v.getTypeCarburant() %></td>
                    <td>
                        <a href="${pageContext.request.contextPath}/vehicules/edit?id=<%=v.getId()%>">Modifier</a>
                        <form action="${pageContext.request.contextPath}/vehicules/delete" method="post" style="display:inline;">
                            <input type="hidden" name="id" value="<%=v.getId()%>"/>
                            <input type="submit" value="Supprimer" onclick="return confirm('Supprimer ce véhicule ?');"/>
                        </form>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    <% } else { %>
        <p>Aucun véhicule trouvé.</p>
    <% } %>
</div>
</body>
</html>
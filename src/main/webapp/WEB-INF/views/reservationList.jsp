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

            <div style="display:flex;gap:12px;align-items:flex-end;margin-bottom:16px;flex-wrap:wrap">
                <div>
                    <label class="text-muted" style="display:block;font-size:0.85em;margin-bottom:4px">Filtrer par date</label>
                    <input type="date" id="dateFiltre" class="form-control" onchange="filtrerEtTrier()">
                </div>
                <div>
                    <label class="text-muted" style="display:block;font-size:0.85em;margin-bottom:4px">Trier par</label>
                    <select id="triFiltre" class="form-control" onchange="filtrerEtTrier()">
                        <option value="dateDesc">Date (recent d'abord)</option>
                        <option value="dateAsc">Date (ancien d'abord)</option>
                        <option value="nom">Nom du lieu (A-Z)</option>
                        <option value="passagers">Passagers (decroissant)</option>
                    </select>
                </div>
                <div>
                    <button type="button" class="btn btn-secondary" onclick="reinitialiser()">Reinitialiser</button>
                </div>
            </div>

            <%
                List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");

                if (reservations == null || reservations.isEmpty()) {
            %>
                <div class="empty-state">Aucune reservation trouvee.</div>
            <% } else { %>
            <table id="reservationTable">
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
                    <tr data-date="<%= r.getDateArrivee() %>"
                        data-lieu="<%= r.getNomLieu() %>"
                        data-passagers="<%= r.getNbPassager() %>">
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

    <script>
    function filtrerEtTrier() {
        var table = document.getElementById('reservationTable');
        if (!table) return;
        var tbody = table.querySelector('tbody');
        var rows = Array.from(tbody.querySelectorAll('tr'));

        var dateFiltre = document.getElementById('dateFiltre').value;
        var tri = document.getElementById('triFiltre').value;

        // Filtrer par date
        rows.forEach(function(row) {
            if (dateFiltre) {
                var rowDate = row.getAttribute('data-date').substring(0, 10);
                row.style.display = (rowDate === dateFiltre) ? '' : 'none';
            } else {
                row.style.display = '';
            }
        });

        // Trier
        var visibleRows = rows.filter(function(r) { return r.style.display !== 'none'; });
        visibleRows.sort(function(a, b) {
            if (tri === 'nom') {
                return a.getAttribute('data-lieu').localeCompare(b.getAttribute('data-lieu'));
            } else if (tri === 'passagers') {
                return parseInt(b.getAttribute('data-passagers')) - parseInt(a.getAttribute('data-passagers'));
            } else if (tri === 'dateAsc') {
                return a.getAttribute('data-date').localeCompare(b.getAttribute('data-date'));
            } else {
                // dateDesc (defaut)
                return b.getAttribute('data-date').localeCompare(a.getAttribute('data-date'));
            }
        });

        // Reordonner dans le DOM
        var hiddenRows = rows.filter(function(r) { return r.style.display === 'none'; });
        visibleRows.forEach(function(row) { tbody.appendChild(row); });
        hiddenRows.forEach(function(row) { tbody.appendChild(row); });
    }

    function reinitialiser() {
        document.getElementById('dateFiltre').value = '';
        document.getElementById('triFiltre').value = 'dateDesc';
        filtrerEtTrier();
    }
    </script>
</body>
</html>

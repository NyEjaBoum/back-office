<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Reservation" %>
<%@ page import="java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Liste des Réservations - Back Office</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .card {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            padding: 40px;
        }
        
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
            font-size: 28px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            font-weight: 500;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
        }
        
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 1px;
        }
        
        tr:hover {
            background-color: #f8f9fa;
        }
        
        .empty-message {
            text-align: center;
            padding: 40px;
            color: #888;
            font-size: 16px;
        }
        
        .nav-links {
            text-align: center;
            margin-top: 30px;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 25px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-hotel {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-client {
            background: #f3e5f5;
            color: #7b1fa2;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>📋 Liste des Réservations</h1>
            
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">
                    ❌ <%= request.getAttribute("error") %>
                </div>
            <% } %>
            
            <%
                List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                
                if (reservations == null || reservations.isEmpty()) {
            %>
                <div class="empty-message">
                    <p>🔍 Aucune réservation trouvée</p>
                </div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Client</th>
                            <th>Passagers</th>
                            <th>Hôtel</th>
                            <th>Date d'arrivée</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Reservation reservation : reservations) { %>
                            <tr>
                                <td><strong>#<%= reservation.getId() %></strong></td>
                                <td><span class="badge badge-client"><%= reservation.getIdClient() %></span></td>
                                <td><%= reservation.getNbPassager() %> 👤</td>
                                <td><span class="badge badge-hotel">🏨 <%= reservation.getNomHotel() %></span></td>
                                <td><%= sdf.format(reservation.getDateArrivee()) %></td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
            
            <div class="nav-links">
                <a href="${pageContext.request.contextPath}/reservations/add" class="btn">➕ Nouvelle réservation</a>
            </div>
        </div>
    </div>
</body>
</html>

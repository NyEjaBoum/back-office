<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Hotel" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ajouter une Réservation - Back Office</title>
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
            max-width: 600px;
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
        
        .form-group {
            margin-bottom: 25px;
        }
        
        label {
            display: block;
            margin-bottom: 8px;
            color: #555;
            font-weight: 600;
            font-size: 14px;
        }
        
        input[type="text"],
        input[type="number"],
        input[type="datetime-local"],
        select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s, box-shadow 0.3s;
        }
        
        input:focus,
        select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        
        .btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            font-weight: 500;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .nav-links {
            text-align: center;
            margin-top: 20px;
        }
        
        .nav-links a {
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        
        .nav-links a:hover {
            text-decoration: underline;
        }
        
        .hint {
            font-size: 12px;
            color: #888;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>🏨 Nouvelle Réservation</h1>
            
            <% if (request.getAttribute("success") != null) { %>
                <div class="alert alert-success">
                    ✅ <%= request.getAttribute("success") %>
                </div>
            <% } %>
            
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">
                    ❌ <%= request.getAttribute("error") %>
                </div>
            <% } %>
            
            <form action="${pageContext.request.contextPath}/reservations/add" method="POST">
                <div class="form-group">
                    <label for="clientId">ID Client</label>
                    <input type="text" 
                           id="clientId" 
                           name="clientId" 
                           pattern="\d{4}" 
                           maxlength="4" 
                           placeholder="Ex: 1234"
                           required>
                    <p class="hint">Doit contenir exactement 4 chiffres</p>
                </div>
                
                <div class="form-group">
                    <label for="nbPassager">Nombre de passagers</label>
                    <input type="number" 
                           id="nbPassager" 
                           name="nbPassager" 
                           min="1" 
                           max="100"
                           placeholder="Ex: 2"
                           required>
                </div>
                
                <div class="form-group">
                    <label for="dateHeureArrivee">Date et heure d'arrivée</label>
                    <input type="datetime-local" 
                           id="dateHeureArrivee" 
                           name="dateHeureArrivee" 
                           required>
                </div>
                
                <div class="form-group">
                    <label for="idHotel">Hôtel</label>
                    <select id="idHotel" name="idHotel" required>
                        <option value="">-- Sélectionner un hôtel --</option>
                        <%
                            List<Hotel> hotels = (List<Hotel>) request.getAttribute("hotels");
                            if (hotels != null) {
                                for (Hotel hotel : hotels) {
                        %>
                            <option value="<%= hotel.getId() %>"><%= hotel.getNom() %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                </div>
                
                <button type="submit" class="btn">Ajouter la réservation</button>
            </form>
            
            <div class="nav-links">
                <a href="${pageContext.request.contextPath}/reservations">📋 Voir toutes les réservations</a>
            </div>
        </div>
    </div>
</body>
</html>

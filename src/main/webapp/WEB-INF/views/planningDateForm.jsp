<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Planification</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=2">
</head>
<body>
    <nav class="nav-bar">
        <span class="nav-brand">Back Office</span>
        <a href="${pageContext.request.contextPath}/reservations">Reservations</a>
        <a href="${pageContext.request.contextPath}/vehicules">Vehicules</a>
        <a href="${pageContext.request.contextPath}/planning" class="active">Planning</a>
    </nav>

    <div class="page page--narrow">
        <div class="card text-center">
            <h1 class="page-title">Planification des trajets</h1>
            <p class="text-muted mb-16">Selectionnez une date pour lancer la planification automatique des vehicules.</p>

            <form action="${pageContext.request.contextPath}/planning" method="post">
                <div class="form-group">
                    <label for="date">Date</label>
                    <input type="date" id="date" name="date" required>
                </div>
                <button type="submit" class="btn btn-primary" style="width:100%">Planifier</button>
            </form>
        </div>
    </div>
</body>
</html>

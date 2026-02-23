<!-- filepath: src/main/webapp/WEB-INF/views/planningDateForm.jsp -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Planification des trajets</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="container">
    <h2>Planifier les trajets</h2>
    <form action="${pageContext.request.contextPath}/planning" method="post">
        <label for="date">Date :</label>
        <input type="date" id="date" name="date" required>
        <button type="submit" class="btn">Planifier</button>
    </form>
</div>
</body>
</html>
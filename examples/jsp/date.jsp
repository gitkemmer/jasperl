<%@ page contentType="text/html" %>

<%-- show current date --%>

<html>
  <head>
    <title>JasPerl JSP Example - Date</title>
  </head>
  <body>
    <h1>JasPerl JSP Example - Date</h1>

    <jsp:useBean id="date" class="java.util.Date"/>
    The current date is ${date}, that's
    <jsp:getProperty name="date" property="time"></jsp:getProperty>
    milliseconds since
    <jsp:setProperty name="date" property="time" value="0"/>
    ${date}.
  </body>
</html>

<%--
multile
comment
--%>

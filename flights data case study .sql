--find the busiest airport by the number os the fights takes off
SELECT TOP 1 a.Name,COUNT(*) AS TotalFlight
FROM Flights f
JOIN Airports a
ON f.origin=a.AirportID
GROUP BY a.Name
ORDER BY TotalFlight DESC;
--total number of tickets sold per airline 
SELECT a.Name AS Airline,
       COUNT(*) AS Ticketsold 
FROM Tickets t 
INNER JOIN Flights f ON t.FlightID=f.FlightID
INNER JOIN Airlines a ON f.AirlineID=a.AirlineID
GROUP BY a.Name
--LIST all flights operated by 'indigo' with airport names (origin and destination) 
SELECT f.FlightID,
       ap.Name AS OriginAirport,
       ap1.Name AS DestinationAirport 
FROM Flights f 
INNER JOIN Airlines a ON f.AirlineID=a.AirlineID
INNER JOIN Airports ap ON f.Origin=ap.AirportID
INNER JOIN Airports ap1 ON f.destination=ap1.AirportID 
WHERE a.Name='Indigo';
--for each airport, show the top airline by number of flights deaprting from there 
WITH CTE_flightrank AS( 
SELECT *,
RANK() OVER(PARTITION BY Origin ORDER BY FlightCount DESC) AS Rn
FROM ( 
      SELECT f.Origin,f.AirlineID,COUNT(*) AS FlightCount
      FROM Flights f  
      GROUP BY f.Origin,f.AirlineID
      )t
)
SELECT A.Name AS AirportName, AL.Name AS AirLineName,r.FlightCount
FROM CTE_flightrank r 
JOIN Airports A ON r.Origin=A.AirportID
JOIN Airports AL ON r.AirlineID= AirlineID
WHERE rn=1
--for each flight , show time taken in hours and categories it as short(<2h) , medium (2-5h) and long(>5h)
SELECT 
     FlightID,
     DepartureTime,
     ArrivalTime,
     DATEDIFF(MINUTE,DepartureTime,ArrivalTime)/60.0 AS DurationHours ,
     CASE 
         WHEN DATEDIFF(MINUTE,DepartureTime,ArrivalTime) <120 THEN 'short'
         WHEN DATEDIFF(MINUTE,DepartureTime,ArrivalTime) <=300 THEN 'Medium'
         ELSE 'Long'
     END AS FlightCategory 
FROM Flights
--show each passenger's first and last flight dates and number of flights 

WITH CTE_flights_no AS ( 
     SELECT PassengerID,
            MIN(f.DepartureTime) AS Firstflight,
            MAX(f.DepartureTime) AS Lastflight,
            COUNT(*) AS Totalflight 
    FROM Tickets T 
    JOIN Flights f ON T.FlightID=f.FlightID
    GROUP BY PassengerID
)
SELECT 
   p.Name,
   cte.Firstflight,
   cte.Lastflight,
   cte.Totalflight
FROM CTE_flights_no cte 
JOIN Passengers p ON cte.PassengerID=p.PassengerID
--find the flights with the highest price tickets sold for each route(origin->destination) 
WITH CTE_routetickets AS( 
    SELECT 
          f.FlightID, 
          f.Origin,
          f.Destination,
          t.TicketID,
          t.Price,
          RANK() OVER(PARTITION BY f.Origin,f.Destination ORDER BY t.Price DESC) AS rank 
    FROM Tickets t 
    JOIN Flights f ON t.FlightID =f.FlightID
) 
SELECT a1.Name As Origin,
       a2.Name AS Destination,
       rt.Price,
       rt.TicketID
FROM CTE_routetickets rt 
JOIN Airports a1 ON rt.Origin=a1.AirportID
JOIN Airports a2 ON rt.Destination=a2.AirportID
WHERE rank=1
--find the highest spending passenger in each frequent flyer status group 
WITH cte_spending AS(
SELECT * ,
     RANK() OVER (PARTITION BY FrequentFlyerStatus ORDER BY TotalSpent DESC) AS rank 
     FROM ( 
           SELECT p.PassengerID,p.Name,p.FrequentFlyerStatus, SUM(t.Price) AS TotalSpent 
           FROM Passengers p 
           JOIN Tickets t 
           ON p.PassengerID=t.PassengerID
           GROUP BY p.PassengerID,p.Name,p.FrequentFlyerStatus
         ) t 
) 
SELECT Name, FrequentFlyerStatus, TotalSpent 
FROM cte_spending 
WHERE rank=1
-- find the total revenue and number of tickets sold for each airline, and rank the airlines based on total revenue 
WITH cte_airlinerevenue AS( 
   SELECT a.AirlineID,a.Name AS AirlineName,
          COUNT(t.TicketID) AS TicketsSold,
          SUM(t.Price) AS TotalRevenue
   FROM Airlines a 
   JOIN Flights f ON a.AirlineID=f.AirlineID
   JOIN Tickets t ON f.FlightID=t.FlightID
   GROUP BY a.AirlineID,a.Name
) 
SELECT 
AirlineName,TicketsSold,TotalRevenue,
RANK() OVER (ORDER BY TotalRevenue DESC ) AS RevenueRank 
FROM cte_airlinerevenue
--for each passenger,identify their most frequently used airline.if a passenger has multiple airlines with the same highest useage, show all such airline 
WITH cte_airlinerank AS(
SELECT *,RANK() OVER(PARTITION BY PassengerID ORDER BY TicketsWithAirline DESC) AS AirlineRank
FROM (
      SELECT p.PassengerID,p.Name AS PassengerName,a.AirlineID,a.Name AS AirlineName,
       COUNT(*) AS TicketsWithAirline
      FROM Passengers p 
      JOIN Tickets t ON p.PassengerID=t.PassengerID
      JOIN Flights f ON t.FlightID=f.FlightID
      JOIN Airlines a ON a.AirlineID=f.AirlineID
      GROUP BY p.PassengerID,p.Name,a.AirlineID,a.Name
      )t
)
SELECT PassengerID,PassengerName,AirlineName,TicketsWithAirline
FROM cte_airlinerank
WHERE AirlineRank=1



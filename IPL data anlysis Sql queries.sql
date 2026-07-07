USE IPLDB;
GO
SELECT * 
FROM dbo.IPLPlayers;
-- find the total spending on players for each team 

SELECT 
Team,
SUM(Price_in_cr) AS 'Total Spending'
FROM IPLPlayers
GROUP BY Team
ORDER BY 'Total Spending' DESC;
--find the top 3 highest_paid 'all rounders'across all teams:

SELECT TOP 3
Player,Team,Price_in_cr
FROM IPLPlayers
WHERE Role='All-rounder'
ORDER BY Price_in_cr DESC;
--Find the highest-priced player in each team:

WITH CTE_MP AS(
   SELECT Team,MAX(Price_in_cr) AS MaxPrice
   FROM IPLPlayers
   GROUP BY Team
)
SELECT i.Team,i.Player,c.MaxPrice
FROM IPLPlayers i 
JOIN CTE_MP c 
ON i.Team=c.Team
WHERE i.Price_in_cr=c.MAXPrice;
--Rank players by their price within each team and list the top 2 for every team:

WITH RankedPlayers AS(
SELECT Player,Team,Price_in_cr,
ROW_NUMBER() OVER(PARTITION BY Team ORDER BY Price_in_cr DESC) AS RankWithinTeam
FROM IPLPlayers
)
SELECT Player,Team,Price_in_cr,RankWithinTeam
FROM RankedPlayers
WHERE RankWithinTeam<=2;
--Find the most expensive player from each team, along with the second -must expensive player's name and price 

WITH RankedPlayers AS(
SELECT Player,Team,Price_in_cr,
ROW_NUMBER() OVER(PARTITION BY Team ORDER BY Price_in_cr DESC) AS RankWithinTeam
FROM IPLPlayers
)
SELECT Team,
   MAX(CASE WHEN RankWithinTeam=1 THEN Player END) AS MostEXpensivePlayer,
   MAX(CASE WHEN RankWithinTeam=1 THEN Price_in_cr END) AS HighestPrice,
   MAX(CASE WHEN RankWithinTeam=2 THEN Player END) AS SecondMostEXpensivePlayer,
   MAX(CASE WHEN RankWithinTeam=2 THEN Price_in_cr END) AS SecondHighestPrice
FROM RankedPlayers
GROUP BY Team
-- CASe-> MArks the value you want and makrs all other rows null.
-- GROUP BY -> combines all rows for the team 
-- MAX-> picks the only non_null value form that group 

--Calculate the precentage contribution of each player's price to their team's total spending 
SELECT Player,Team,Price_in_cr,
CAST(Price_in_cr/(SUM(Price_in_cr) OVER(PARTITION BY Team)) * 100 AS DECIMAL (10,2)) AS ContributionPrecentage
FROM IPLPlayers

--classify players as'high','mediam', or'low' priced based on the following rules:
--high:price>15 crores
--low:price<5 crores 
--mediam: price between 5 crore and 15 crore
-- and find out the number of players in each bracket 
WITH CTE_BR AS(
SELECT Team,Player,Price_in_cr,
   CASE
       WHEN Price_in_cr > 15 THEN'High'
       WHEN Price_in_cr BETWEEN 5 AND 15 THEN 'Medium'
       ELSE 'Low'
       END AS PriceCategory 
FROM IPLPlayers
)
SELECT Team,PriceCategory,COUNT(*) AS 'NO_of_Players'
FROM CTE_BR 
GROUP BY Team,PriceCategory
ORDER BY Team,PriceCategory

--find the avwerage price of indian players and comapre it with overseas players using a subquery 
SELECT 
'Indian' AS PlayerType ,
   (SELECT AVG(Price_in_cr)
    FROM IPLPlayers
    WHERE Type LIKE'Indian%') As AvgPrice 
UNION ALL 
SELECT 
 'Overseas' AS PlayerType,
   (SELECT AVG(Price_in_cr)
   FROM IPLPlayers
   WHERE Type LIKE 'Overseas%') As AvgPrice

--identify the players whpo earn more than the avergae price of their team 
SELECT 
Player,Team,Price_in_cr
FROM IPLPlayers p
WHERE Price_in_cr>(
                   SELECT AVG(price_in_cr)
                   FROM IPLPlayers
                   WHERE Team=p.Team)

--for each role,find the most expensive player and their price using a correlated subquery 

SELECT Player,Team,Role,Price_in_cr 
FROM IPLPlayers p 
WHERE Price_in_cr =(
                    SELECT MAX(Price_in_cr)
                    FROM IPLPlayers
                    WHERE ROLE=p.Role
                    )



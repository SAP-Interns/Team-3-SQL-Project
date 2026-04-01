--Products ranked by net revenue in a given period,showcasing top 10 by each country
SELECT *
FROM (
    SELECT 
        ctry.Name AS Country,
        p.Name AS Product,
        SUM(oli.TotalPrice) AS Revenue,
        RANK() OVER (
            PARTITION BY ctry.Name 
            ORDER BY SUM(oli.TotalPrice) DESC
        ) AS rnk
    FROM OrderLineItem oli
    INNER JOIN SaleOrder so ON oli.SaleOrderID = so.ID
    INNER JOIN Customer c ON so.CustomerID = c.ID
    INNER JOIN Country ctry ON c.CountryID = ctry.ID
    INNER JOIN Product p ON oli.ProductID = p.ID
    WHERE so.OrderDate BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY ctry.Name, p.Name
) t
WHERE rnk <= 10;
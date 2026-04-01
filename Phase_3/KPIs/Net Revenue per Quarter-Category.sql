--Net Revenue( Per Quarter,Category)
SELECT 
    d.Year,
    d.Quarter,
    cat.Name AS Category,
    ROUND(SUM(oli.TotalPrice),2) AS NetRevenue
FROM OrderLineItem oli
INNER JOIN Product p ON oli.ProductID = p.ID
INNER JOIN Category cat ON p.CategoryID = cat.ID
INNER JOIN SaleOrder so ON oli.SaleOrderID = so.ID
INNER JOIN Date d ON so.OrderDateKey = d.DateKey
GROUP BY d.Year, d.Quarter, cat.Name;

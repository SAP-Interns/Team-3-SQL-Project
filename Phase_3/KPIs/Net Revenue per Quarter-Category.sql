--Net Revenue( Per Quarter,Category)
SELECT 
    d.Year,
    d.Quarter,
    cat.Name AS Category,
    ROUND(SUM(oli.TotalPrice),2) AS NetRevenue
FROM OrderLineItem oli
JOIN Product p ON oli.ProductID = p.ID
JOIN Category cat ON p.CategoryID = cat.ID
JOIN SaleOrder so ON oli.SaleOrderID = so.ID
JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY d.Year, d.Quarter, cat.Name;

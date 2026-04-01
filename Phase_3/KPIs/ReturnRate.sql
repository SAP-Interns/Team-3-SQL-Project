--Return Rate %
SELECT 
    p.Name AS Product,
    d.Quarter,
    (COUNT(r.ID) * 1.0 / SUM(oli.Quantity)) * 100 AS ReturnRate
FROM OrderLineItem oli
INNER JOIN Product p ON oli.ProductID = p.ID
INNER JOIN SaleOrder so ON oli.SaleOrderID = so.ID
INNER JOIN Date d ON so.OrderDateKey = d.DateKey
LEFT JOIN [Return] r ON oli.ID = r.OrderLineItemID
GROUP BY p.Name, d.Quarter;

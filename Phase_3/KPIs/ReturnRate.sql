--Return Rate %
SELECT 
    p.Name AS Product,
    d.Quarter,
    (COUNT(r.ID) * 1.0 / SUM(oli.Quantity)) * 100 AS ReturnRate
FROM OrderLineItem oli
JOIN Product p ON oli.ProductID = p.ID
JOIN SaleOrder so ON oli.SaleOrderID = so.ID
JOIN Date d ON so.OrderDate = d.FullDate
LEFT JOIN [Return] r ON oli.ID = r.OrderLineItemID
GROUP BY p.Name, d.Quarter;

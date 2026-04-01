-- High Orders but Low Value Customers
SELECT 
    c.Name,
    COUNT(so.ID) AS TotalOrders,
    SUM(oli.TotalPrice) / COUNT(so.ID) AS AvgOrderValue
FROM Customer c
INNER JOIN SaleOrder so ON c.ID = so.CustomerID
INNER JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
WHERE so.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.Name
HAVING 
    COUNT(so.ID) > 20
    AND (SUM(oli.TotalPrice) / COUNT(so.ID)) < 1000;
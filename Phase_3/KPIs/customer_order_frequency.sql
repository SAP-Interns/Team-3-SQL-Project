--Average number of orders per customer per quarter
SELECT 
    at.Name AS CustomerTier,
    d.Quarter,
    COUNT(so.ID) * 1.0 / COUNT(DISTINCT c.ID) AS AvgOrdersPerCustomer
FROM SaleOrder so
INNER JOIN Customer c ON so.CustomerID = c.ID
INNER JOIN AccountTier at ON c.AccountTierID = at.ID
INNER JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY at.Name, d.Quarter;
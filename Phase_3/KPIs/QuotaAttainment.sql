-- Quota Attainment %
SELECT 
    sr.Name,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / q.TargetAmount * 100,2) AS [Quota Attainment]
FROM SaleOrder so
INNER JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
INNER JOIN SalesRepresentative sr ON so.SalesRepresentativeID = sr.ID
INNER JOIN Quota q ON sr.ID = q.SalesRepresentativeID
INNER JOIN Date d ON so.OrderDateKey = d.DateKey
GROUP BY sr.Name, d.MonthNum, q.TargetAmount;

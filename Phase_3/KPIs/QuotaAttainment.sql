-- Quota Attainment %
SELECT 
    sr.Name,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / q.TargetAmount * 100,2) AS [Quota Attainment]
FROM SaleOrder so
JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
JOIN SalesRepresentative sr ON so.SalesRepresentativeID = sr.ID
JOIN Quota q ON sr.ID = q.SalesRepresentativeID
JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY sr.Name, d.MonthNum, q.TargetAmount;

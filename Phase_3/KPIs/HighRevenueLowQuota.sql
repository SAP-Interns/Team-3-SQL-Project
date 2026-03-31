--High Revenue but Low Quota
SELECT 
    sr.Name,
    d.Year,
    d.Quarter,
    SUM(oli.TotalPrice) AS Revenue,
    (SUM(oli.TotalPrice) / q.TargetAmount) * 100 AS QuotaAttainment
FROM SaleOrder so
JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
JOIN SalesRepresentative sr ON so.SalesRepresentativeID = sr.ID
JOIN Quota q ON sr.ID = q.SalesRepresentativeID
JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY sr.Name, d.Year, d.Quarter, q.TargetAmount
HAVING 
    SUM(oli.TotalPrice) > 500000
    AND (SUM(oli.TotalPrice) / q.TargetAmount) * 100 < 80;

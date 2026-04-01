--Average Order Value
SELECT 
    r.Name AS Region,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / COUNT(DISTINCT so.ID),2) AS AvgOrderValue
FROM SaleOrder so
INNER JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
INNER JOIN SalesRepresentative sr ON so.SalesRepresentativeID = sr.ID
INNER JOIN Region r ON sr.RegionID = r.ID
INNER JOIN Date d ON so.OrderDateKey = d.DateKey
GROUP BY r.Name, d.MonthNum
ORDER BY d.MonthNum;
--Average Order Value
SELECT 
    r.Name AS Region,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / COUNT(DISTINCT so.ID),2) AS AvgOrderValue
FROM SaleOrder so
JOIN OrderLineItem oli ON so.ID = oli.SaleOrderID
JOIN SalesRepresentative sr ON so.SalesRepresentativeID = sr.ID
JOIN Region r ON sr.RegionID = r.ID
JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY r.Name, d.MonthNum
ORDER BY d.MonthNum;
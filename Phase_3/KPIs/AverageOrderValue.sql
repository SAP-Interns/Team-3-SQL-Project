--Average Order Value
SELECT 
    r.Name AS Region,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / COUNT(DISTINCT so.ID),2) AS AvgOrderValue
FROM fact_sale_orders so
INNER JOIN fact_order_line_items oli ON so.ID = oli.SaleOrderID
INNER JOIN dim_sales_reps sr ON so.SalesRepresentativeID = sr.ID
INNER JOIN dim_regions r ON sr.RegionID = r.ID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY r.Name, d.MonthNum
ORDER BY d.MonthNum;
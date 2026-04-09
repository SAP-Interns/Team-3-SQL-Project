-- Quota Attainment %
WITH Quotas AS 
(
    SELECT 
    q.SalesRepresentativeID,
    SUM(q.TargetAmount) AS target
    FROM fact_quotas q
    GROUP BY q.SalesRepresentativeID
)
SELECT 
    sr.Name,
    d.MonthNum,
    SUM(oli.TotalPrice) AS TotalSalesAmount,
    q.target AS TargetAmount,
    ROUND(SUM(oli.TotalPrice) / q.target * 100,2) AS [Quota Attainment]
FROM fact_sale_orders so
INNER JOIN fact_order_line_items oli ON so.ID = oli.SaleOrderID
INNER JOIN dim_sales_reps sr ON so.SalesRepresentativeID = sr.ID
LEFT JOIN Quotas q ON q.SalesRepresentativeID = sr.ID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY sr.Name, d.MonthNum, q.target;

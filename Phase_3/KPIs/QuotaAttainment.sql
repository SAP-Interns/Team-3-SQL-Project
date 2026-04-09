-- Quota Attainment %
SELECT 
    sr.Name,
    d.MonthNum,
    ROUND(SUM(oli.TotalPrice) / q.TargetAmount * 100,2) AS [Quota Attainment]
FROM fact_sale_orders so
INNER JOIN fact_order_line_items oli ON so.ID = oli.SaleOrderID
INNER JOIN dim_sales_reps sr ON so.SalesRepresentativeID = sr.ID
INNER JOIN fact_quotas q ON sr.ID = q.SalesRepresentativeID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY sr.Name, d.MonthNum, q.TargetAmount;

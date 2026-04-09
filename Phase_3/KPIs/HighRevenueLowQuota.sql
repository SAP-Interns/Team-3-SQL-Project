--High Revenue but Low Quota
SELECT 
    sr.Name,
    d.Year,
    d.Quarter,
    SUM(oli.TotalPrice) AS Revenue,
    (SUM(oli.TotalPrice) / q.TargetAmount) * 100 AS QuotaAttainment
FROM fact_sale_orders so
INNER JOIN fact_order_line_items oli ON so.ID = oli.SaleOrderID
INNER JOIN dim_sales_reps sr ON so.SalesRepresentativeID = sr.ID
INNER JOIN fact_quotas q ON sr.ID = q.SalesRepresentativeID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY sr.Name, d.Year, d.Quarter, q.TargetAmount
HAVING 
    SUM(oli.TotalPrice) > 500000
    AND (SUM(oli.TotalPrice) / q.TargetAmount) * 100 < 80;

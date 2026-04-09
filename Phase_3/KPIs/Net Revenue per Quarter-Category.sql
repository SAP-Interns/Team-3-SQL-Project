--Net Revenue( Per Quarter,Category)
SELECT 
    d.Year,
    d.Quarter,
    cat.Name AS Category,
    ROUND(SUM(oli.TotalPrice),2) AS NetRevenue
FROM fact_order_line_items oli
INNER JOIN dim_products p ON oli.ProductID = p.ID
INNER JOIN dim_categories cat ON p.CategoryID = cat.ID
INNER JOIN fact_sale_orders so ON oli.SaleOrderID = so.ID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY d.Year, d.Quarter, cat.Name;

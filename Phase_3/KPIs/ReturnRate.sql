--Return Rate %
SELECT 
    p.Name AS Product,
    d.Quarter,
    ROUND(ISNULL((SUM(r.ReturnQuantity) * 1.0 / SUM(oli.Quantity)) * 100, 0), 2) AS [ReturnRate %]
FROM fact_order_line_items oli
INNER JOIN dim_products p ON oli.ProductID = p.ID
INNER JOIN fact_sale_orders so ON oli.SaleOrderID = so.ID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
LEFT JOIN fact_returns r ON oli.ID = r.OrderLineItemID
GROUP BY p.Name, d.Quarter;

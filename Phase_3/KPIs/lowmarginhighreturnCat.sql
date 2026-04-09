--Low Margin and high return Categories
SELECT 
    cat.Name,
    ((SUM(oli.TotalPrice) - SUM(oli.Quantity * p.UnitCost)) / SUM(oli.TotalPrice)) * 100 AS Margin,
    (COUNT(r.ID) * 1.0 / SUM(oli.Quantity)) * 100 AS ReturnRate
FROM fact_order_line_items oli
INNER JOIN dim_products p ON oli.ProductID = p.ID
INNER JOIN dim_categories cat ON p.CategoryID = cat.ID
LEFT JOIN fact_returns r ON oli.ID = r.OrderLineItemID
GROUP BY cat.Name
HAVING 
    ((SUM(oli.TotalPrice) - SUM(oli.Quantity * p.UnitCost)) / SUM(oli.TotalPrice)) * 100 < 25
    AND (COUNT(r.ID) * 1.0 / SUM(oli.Quantity)) * 100 > 10;

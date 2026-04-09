--Gross Margin
SELECT 
    cat.Name AS Category,
    SUM(oli.TotalPrice) AS NetRevenue,
    SUM(oli.Quantity * p.UnitCost) AS TotalCost,
    ROUND(((SUM(oli.TotalPrice) - SUM(oli.Quantity * p.UnitCost)) 
        / SUM(oli.TotalPrice)) * 100,2) AS GrossMarginPercent
FROM fact_order_line_items oli
INNER JOIN dim_products p ON oli.ProductID = p.ID
INNER JOIN dim_categories cat ON p.CategoryID = cat.ID
GROUP BY cat.Name;
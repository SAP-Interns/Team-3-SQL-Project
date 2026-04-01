--Gross Margin
SELECT 
    cat.Name AS Category,
    SUM(oli.TotalPrice) AS NetRevenue,
    SUM(oli.Quantity * p.UnitCost) AS TotalCost,
    ROUND(((SUM(oli.TotalPrice) - SUM(oli.Quantity * p.UnitCost)) 
        / SUM(oli.TotalPrice)) * 100,2) AS GrossMarginPercent
FROM OrderLineItem oli
INNER JOIN Product p ON oli.ProductID = p.ID
INNER JOIN Category cat ON p.CategoryID = cat.ID
GROUP BY cat.Name;
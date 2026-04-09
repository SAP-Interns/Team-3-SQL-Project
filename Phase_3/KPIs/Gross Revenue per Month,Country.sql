--Gross Revenue per Month,Country
SELECT 
    d.Year,
    d.MonthNum,
    ctry.Name AS Country,
    SUM(oli.Quantity * p.ListingPrice) AS GrossRevenue
FROM fact_order_line_items oli
INNER JOIN fact_sale_orders so ON oli.SaleOrderID = so.ID
INNER JOIN dim_customers c ON so.CustomerID = c.ID
INNER JOIN dim_territories t on t.ID = c.TerritoryID
INNER JOIN dim_countries ctry ON ctry.ID = t.CountryID
INNER JOIN dim_products p ON oli.ProductID = p.ID
INNER JOIN dim_date d ON so.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNum, ctry.Name
Order by d.Year,d.MonthNum;


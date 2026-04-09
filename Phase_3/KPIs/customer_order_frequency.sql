--Average number of orders per customer per quarter
SELECT 
    at.Name AS CustomerTier,
    d.Quarter,
    COUNT(so.ID) * 1.0 / COUNT(DISTINCT c.ID) AS AvgOrdersPerCustomer
FROM fact_sale_orders so
INNER JOIN dim_customers c ON so.CustomerID = c.ID
INNER JOIN dim_account_tiers at ON c.AccountTierID = at.ID
INNER JOIN dim_date d ON so.OrderDate = d.FullDate
GROUP BY at.Name, d.Quarter;
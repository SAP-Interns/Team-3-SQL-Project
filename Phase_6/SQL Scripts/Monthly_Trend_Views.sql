--31.	vw_monthly_trend: A time-series view showing month-by-month revenue, order volume, 
--average order value, and month-over-month percentage change at the country level.

CREATE VIEW [dbo].[vw_monthly_trend] AS
WITH MonthlyCountryStats AS (
    SELECT 
        D.Year,
        D.MonthNum,
        D.MonthName,
        CO.Name AS CountryName,
        SUM(O.TotalPrice) AS Revenue,
        COUNT(DISTINCT SO.ID) AS OrderVolume,
        ROUND(SUM(O.TotalPrice) / NULLIF(COUNT(DISTINCT SO.ID), 0), 2) AS AvgOrderValue
    FROM [dbo].[fact_sale_orders] SO
    INNER JOIN [dbo].[fact_order_line_items] O ON O.SaleOrderID = SO.ID
    INNER JOIN [dbo].[dim_date] D ON D.DateKey = SO.OrderDateKey
    INNER JOIN [dbo].[dim_customers] C ON C.ID = SO.CustomerID
    INNER JOIN [dbo].[dim_territories] T ON T.ID = C.TerritoryID
    INNER JOIN [dbo].[dim_countries] CO ON CO.ID = T.CountryID
    GROUP BY D.Year, D.MonthNum, D.MonthName, CO.Name
)
SELECT 
    Year,
    MonthNum,
    MonthName,
    CountryName,
    Revenue,
    OrderVolume,
    AvgOrderValue,
    LAG(Revenue) OVER (PARTITION BY CountryName ORDER BY Year, MonthNum) AS PreviousMonthRevenue,
    ROUND(
        ((Revenue - LAG(Revenue) OVER (PARTITION BY CountryName ORDER BY Year, MonthNum)) 
        / NULLIF(LAG(Revenue) OVER (PARTITION BY CountryName ORDER BY Year, MonthNum), 0)) * 100, 
    2) AS MoM_Revenue_Change_Pct
FROM MonthlyCountryStats
GO
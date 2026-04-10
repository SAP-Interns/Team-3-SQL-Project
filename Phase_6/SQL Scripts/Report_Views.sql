/*
vw_sales_executive_summary: A single view that a C-level executive can query to see total
revenue, gross margin, order count, average order value, and quota attainment for any given
period and region combination.
*/
CREATE VIEW [dbo].[vw_sales_executive_summary] AS
    SELECT 
    Year,
    Quarter,
    RegionName,
    TotalRevenue,
    TotalGrossMargin,
    OrderCount,
    TotalRevenue / NULLIF(OrderCount, 0) AS AvgOrderValue
    FROM [dbo].[vw_summary_regional_metrics]
    ORDER BY year ASC, Quarter ASC
GO


/*
vw_customer_360: A comprehensive customer profile view showing each customer&#39;s lifetime
revenue, order frequency, last order date, average order value, return rate, assigned rep, and
RFM segment classification.
*/
CREATE VIEW [dbo].[vw_customer_360] AS
    SELECT 
    CustomerID,
    CustomerName,
    SalesRepID,
    SalesRepName,
    TotalOrders,
    Revenue,
    LastOrderDate,
    AvgOrderValue,
    CASE 
        WHEN Revenue > 100000 THEN 'Platinum'
        WHEN Revenue > 50000 THEN 'Gold'
        ELSE 'Standard'
    END AS RFM_Segment
    FROM [dbo].[vw_summary_customer_metrics]
GO
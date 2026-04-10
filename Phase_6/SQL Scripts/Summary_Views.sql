/* CUSTOMER SUMMARY PERFORMANCE */
CREATE VIEW [dbo].[vw_summary_customer_metrics] AS
    SELECT 
    CustomerID,
    CustomerName,
    SalesRepID,
    SalesRepName,
    COUNT(DISTINCT SaleOrderID) AS TotalOrders,
    SUM(NetRevenue) AS Revenue,
    MAX(OrderDate) AS LastOrderDate,
    ROUND(AVG(NetRevenue), 2) AS AvgOrderValue
    FROM [dbo].[vw_base_sales]
    GROUP BY CustomerID, CustomerName, SalesRepName, SalesRepID
GO

/* REGION SALES SUMMARY */
CREATE VIEW [dbo].[vw_summary_regional_metrics] AS
    SELECT 
    Year,
    Quarter,
    RegionName,
    SUM(NetRevenue) AS TotalRevenue,
    SUM(GrossMarginAmount) AS TotalGrossMargin,
    COUNT(DISTINCT SaleOrderID) AS OrderCount
    FROM [dbo].[vw_base_sales]
    GROUP BY Year, Quarter, RegionName
GO

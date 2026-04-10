
/* SALES BASE VIEW */
CREATE VIEW [dbo].[vw_base_sales] AS
    SELECT 
    SO.ID AS SaleOrderID,
    SO.OrderDate,
    SO.ShippingDate,
    D.Year,
    D.Quarter,
    D.MonthNum,
    D.MonthName,
    D.WeekNum,
    D.DayOfWeek,
    D.IsBusinessDay,
    T.Name AS TerritoryName,
    T.ID AS TerritoryID,
    R.Name AS RegionName,
    R.ID AS RegionID,
    CO.Name AS CountryName,
    CO.ID AS CountryID,
    C.Name AS CustomerName,
    C.ID AS CustomerID,
    SR.Name AS SalesRepName,
    SR.ID AS SalesRepID,
    P.Name AS ProductName,
    P.ID AS ProductID,
    CC.Name AS CategoryName,
    CC.ID AS CategoryID,
    O.ID AS LineItemID,
    O.Quantity,
    O.UnitPrice,
    O.TotalPrice AS NetRevenue,
    (O.TotalPrice - (p.UnitCost * O.Quantity)) AS GrossMarginAmount,
    P.UnitCost * O.Quantity AS TotalCost,
    PR.Name AS PromotionName,
    PR.ID AS PromotionID
    FROM fact_sale_orders SO
    INNER JOIN fact_order_line_items O ON O.SaleOrderID = SO.ID
    INNER JOIN dim_date D ON D.DateKey = SO.OrderDateKey
    INNER JOIN dim_customers C ON C.ID = SO.CustomerID
    INNER JOIN dim_sales_reps SR ON SR.ID = SO.SalesRepresentativeID
    INNER JOIN dim_products P ON P.ID = O.ProductID
    INNER JOIN dim_categories CC ON CC.ID = P.CategoryID
    INNER JOIN dim_territories T ON T.ID = C.TerritoryID
    INNER JOIN dim_countries CO ON CO.ID = T.CountryID
    INNER JOIN dim_regions R ON R.ID = CO.RegionID
    LEFT JOIN dim_promotions PR ON P.ID = O.PromotionID
GO

/* RETURNS BASE VIEW */
CREATE VIEW [dbo].[vw_base_returns] AS
    SELECT 
    RT.ID AS ReturnID,
    O.SaleOrderID,
    RT.ReturnDate,
    D.Year,
    D.Quarter,
    D.MonthNum,
    D.MonthName,
    D.WeekNum,
    D.DayOfWeek,
    D.IsBusinessDay,
    T.Name AS TerritoryName,
    T.ID AS TerritoryID,
    R.Name AS RegionName,
    R.ID AS RegionID,
    CO.Name AS CountryName,
    CO.ID AS CountryID,
    P.Name AS ProductName,
    O.ProductID,
    CC.Name as CategoryName,
    P.CategoryID,
    RR.Name AS ReturnReasonName,
    RR.ID AS ReturnReasonID,
    RT.ReturnQuantity,
    RT.CreditAmount
    FROM fact_returns RT
    INNER JOIN fact_order_line_items O ON O.ID = RT.OrderLineItemID
    INNER JOIN dim_date D ON D.DateKey = RT.ReturnDateKey
    INNER JOIN dim_products P ON P.ID = O.ProductID
    INNER JOIN dim_categories CC ON CC.ID = P.CategoryID
    INNER JOIN fact_sale_orders SO ON SO.ID = O.SaleOrderID
    INNER JOIN dim_customers C ON C.ID = SO.CustomerID
    INNER JOIN dim_territories T ON T.ID = C.TerritoryID
    INNER JOIN dim_countries CO ON CO.ID = T.CountryID
    INNER JOIN dim_regions R ON R.ID = CO.RegionID
    INNER JOIN dim_return_reasons RR ON RR.ID = RT.ReturnReasonID
GO

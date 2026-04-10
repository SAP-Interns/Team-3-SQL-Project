--32.	vw_returns_analysis: A view specifically for the operations team showing return rate by product category, 
--by country, and by reason code, with total credit note value per period.

CREATE VIEW [dbo].[vw_returns_analysis] AS
    SELECT 
        D.Year,
        D.MonthNum,
        D.MonthName,
        CO.Name AS CountryName,
        CC.Name AS CategoryName,
        RR.Name AS ReturnReasonName,
        COUNT(DISTINCT RT.ID) AS TotalReturnOrders,
        SUM(RT.ReturnQuantity) AS TotalItemsReturned,
        SUM(RT.CreditAmount) AS TotalCreditNoteValue
    FROM [dbo].[fact_returns] RT
    INNER JOIN [dbo].[dim_date] D ON D.DateKey = RT.ReturnDateKey
    INNER JOIN [dbo].[dim_return_reasons] RR ON RR.ID = RT.ReturnReasonID
    INNER JOIN [dbo].[fact_order_line_items] O ON O.ID = RT.OrderLineItemID
    INNER JOIN [dbo].[dim_products] P ON P.ID = O.ProductID
    INNER JOIN [dbo].[dim_categories] CC ON CC.ID = P.CategoryID
    -- Link back to Country via the original Sale Order
    INNER JOIN [dbo].[fact_sale_orders] SO ON SO.ID = O.SaleOrderID
    INNER JOIN [dbo].[dim_customers] C ON C.ID = SO.CustomerID
    INNER JOIN [dbo].[dim_territories] T ON T.ID = C.TerritoryID
    INNER JOIN [dbo].[dim_countries] CO ON CO.ID = T.CountryID
    GROUP BY 
        D.Year, D.MonthNum, D.MonthName, CO.Name, CC.Name, RR.Name
GO
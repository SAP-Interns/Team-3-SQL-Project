CREATE VIEW dbo.vw_product_performance AS
WITH sales_agg AS (
    SELECT 
        ProductID,
        ProductName,
        CategoryID,
        CategoryName,
        SUM(Quantity) AS TotalUnitsSold,
        SUM(NetRevenue) AS TotalRevenue,
        SUM(GrossMarginAmount) AS TotalGrossMargin
    FROM dbo.vw_base_sales
    GROUP BY 
        ProductID, ProductName, CategoryID, CategoryName
),
returns_agg AS (
    SELECT 
        ProductID,
        SUM(ReturnQuantity) AS TotalReturnedUnits
    FROM dbo.vw_base_returns
    GROUP BY ProductID
)

SELECT 
    s.ProductID,
    s.ProductName,
    s.CategoryID,
    s.CategoryName,
    s.TotalUnitsSold,
    s.TotalRevenue,

    -- Gross Margin %
    CASE 
        WHEN s.TotalRevenue = 0 THEN 0
        ELSE s.TotalGrossMargin * 1.0 / s.TotalRevenue
    END AS GrossMarginPct,

    -- Return Rate
    CASE 
        WHEN s.TotalUnitsSold = 0 THEN 0
        ELSE ISNULL(r.TotalReturnedUnits, 0) * 1.0 / s.TotalUnitsSold
    END AS ReturnRate,

    -- Ranking within Category
    RANK() OVER (
        PARTITION BY s.CategoryID
        ORDER BY s.TotalRevenue DESC
    ) AS CategoryRank

FROM sales_agg s
LEFT JOIN returns_agg r 
    ON s.ProductID = r.ProductID;
GO

select *
from dbo.vw_product_performance
CREATE VIEW dbo.vw_rep_performance_scorecard AS
WITH current_period AS (
    SELECT 
        YEAR(GETDATE()) AS CurrentYear,
        DATEPART(QUARTER, GETDATE()) AS CurrentQuarter,
        CAST(GETDATE() AS DATE) AS Today
),

sales_filtered AS (
    SELECT 
        s.*,
        cp.CurrentQuarter
    FROM dbo.vw_base_sales s
    CROSS JOIN current_period cp
    WHERE 
        s.Year = cp.CurrentYear
        AND s.OrderDate <= cp.Today
),

agg AS (
    SELECT 
        SalesRepID,
        SalesRepName,
        RegionID,
        RegionName,

        SUM(CASE 
            WHEN Quarter = CurrentQuarter
            THEN NetRevenue ELSE 0 
        END) AS QuarterRevenue,

        SUM(NetRevenue) AS YTDRevenue,

        COUNT(DISTINCT CustomerID) AS CustomerCount

    FROM sales_filtered
    GROUP BY 
        SalesRepID, SalesRepName, RegionID, RegionName
)

SELECT 
    a.*,
    RANK() OVER (
        PARTITION BY RegionID
        ORDER BY YTDRevenue DESC
    ) AS RegionalRank
FROM agg a;

--1.Computes customer Recency, Frequency, and Monetary values and classifies them into RFM segments (e.g., Champions, Loyal, At Risk)
WITH customer_rfm AS (
    SELECT 
        c.ID AS CustomerID,
        c.Name AS CustomerName,
        DATEDIFF(day, MAX(o.OrderDate), GETDATE()) AS RecencyDays,
        COUNT(DISTINCT o.ID) AS Frequency,
        SUM(oli.TotalPrice) AS Monetary
    FROM Customer c
    LEFT JOIN SaleOrder o 
        ON c.ID = o.CustomerID 
        AND o.OrderDate >= DATEADD(year, -1, GETDATE())
    LEFT JOIN OrderLineItem oli 
        ON o.ID = oli.SaleOrderID
    GROUP BY c.ID, c.Name
)
SELECT 
    CustomerID,
    CustomerName,
    RecencyDays,
    Frequency,
    Monetary,
    CASE 
        WHEN RecencyDays <= 30 AND Frequency >= 10 AND Monetary >= 10000 THEN 'Champions'
        WHEN RecencyDays <= 60 AND Frequency >= 5 THEN 'Loyal'
        WHEN RecencyDays > 120 AND Frequency >= 5 THEN 'At Risk'
        WHEN RecencyDays > 180 AND Frequency < 2 THEN 'Lost'
        WHEN RecencyDays <= 30 AND Frequency = 1 THEN 'New'
        ELSE 'Standard'
    END AS RFMSegment
FROM customer_rfm;

--2.Calculates month-over-month revenue trends per country including previous month revenue, absolute change, and percentage change
WITH monthly_revenue AS (
    SELECT 
        co.Name AS CountryName,
        YEAR(o.OrderDate) AS SalesYear,
        MONTH(o.OrderDate) AS SalesMonth,
        SUM(oli.TotalPrice) AS NetRevenue
    FROM SaleOrder o
    INNER JOIN OrderLineItem oli ON o.ID = oli.SaleOrderID
    INNER JOIN Customer c  ON o.CustomerID = c.ID
    INNER JOIN Territory t ON c.TerritoryID = t.ID
    INNER JOIN Country co ON t.CountryID = co.ID
    GROUP BY co.Name, YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT
    CountryName,
    SalesYear,
    SalesMonth,
    NetRevenue,
    LAG(NetRevenue) OVER (
        PARTITION BY CountryName
        ORDER BY SalesYear, SalesMonth
    ) AS PrevMonthRevenue,
    ROUND(NetRevenue - LAG(NetRevenue) OVER (PARTITION BY CountryName ORDER BY SalesYear, SalesMonth),2) AS AbsoluteChange,
    ROUND((NetRevenue - LAG(NetRevenue) OVER (PARTITION BY CountryName ORDER BY SalesYear, SalesMonth)) / NULLIF(LAG(NetRevenue) 
	OVER (PARTITION BY CountryName ORDER BY SalesYear, SalesMonth),0) * 100,2) AS PctChange
FROM monthly_revenue;


--3.Calculates quarterly revenue per region and running total within each year
WITH quarterly_revenue AS (
    SELECT 
        r.Name AS RegionName,
        YEAR(o.OrderDate) AS SalesYear,
        DATEPART(QUARTER, o.OrderDate) AS SalesQuarter,
        ROUND(SUM(oli.TotalPrice), 2) AS QuarterlyRevenue
    FROM SaleOrder o
    INNER JOIN OrderLineItem oli ON o.ID = oli.SaleOrderID
    INNER JOIN Customer c ON o.CustomerID = c.ID
    INNER JOIN Territory t ON c.TerritoryID = t.ID
    INNER JOIN Country co ON t.CountryID = co.ID
    INNER JOIN Region r ON co.RegionID = r.ID
    GROUP BY 
        r.Name,
        YEAR(o.OrderDate),
        DATEPART(QUARTER, o.OrderDate)
)
SELECT 
    RegionName,
    SalesYear,
    SalesQuarter,
    QuarterlyRevenue,
    ROUND(SUM(QuarterlyRevenue) OVER (PARTITION BY RegionName, SalesYear ORDER BY SalesQuarter), 2) AS RunningQuarterlyRevenue
FROM quarterly_revenue
ORDER BY RegionName, SalesYear, SalesQuarter;

--4.Ranks sales representatives within each region based on quota attainment percentage for the most recent completed quarter
WITH rep_performance AS (
    SELECT 
        sr.Name AS RepName,
        r.Name AS RegionName,
        SUM(ISNULL(q.TargetAmount, 0)) / 4.0 AS QuarterlyQuotaTarget, 
        SUM(oli.TotalPrice) AS ActualRevenue,
        CASE 
            WHEN SUM(ISNULL(q.TargetAmount, 0)) <= 0 THEN 0.0
            ELSE (SUM(oli.TotalPrice) * 100.0) / (SUM(q.TargetAmount) / 4.0)
        END AS AttainmentPct
    FROM SalesRepresentative sr
    INNER JOIN Region r ON sr.RegionID = r.ID
    INNER JOIN SaleOrder o ON sr.ID = o.SalesRepresentativeID
    INNER JOIN OrderLineItem oli ON o.ID = oli.SaleOrderID
    LEFT JOIN Quota q 
        ON sr.ID = q.SalesRepresentativeID 
        AND q.FiscalPeriod = CONCAT('FY', YEAR(DATEADD(quarter, -1, GETDATE())))
    WHERE DATEPART(quarter, o.OrderDate) = DATEPART(quarter, DATEADD(quarter, -1, GETDATE()))
      AND YEAR(o.OrderDate) = YEAR(DATEADD(quarter, -1, GETDATE()))
    GROUP BY sr.ID, sr.Name, r.Name
)
SELECT 
    RANK() OVER (PARTITION BY RegionName ORDER BY AttainmentPct DESC) AS RegionalRank,
    RepName,
    ROUND(AttainmentPct * 100, 1) AS [Attainment %],
    ROUND(AVG(AttainmentPct) OVER (PARTITION BY RegionName) * 100, 1) AS [Region Avg %]
FROM rep_performance;


--5.Identifies the highest-revenue customer in each country for the current year using row-based ranking
SELECT 
    CustomerName,
    CountryName,
    TotalRevenue,
    AccountTierName
FROM (
    SELECT 
        c.Name AS CustomerName,
        co.Name AS CountryName,
        at.Name AS AccountTierName,
        SUM(oli.TotalPrice) AS TotalRevenue,
        ROW_NUMBER() OVER (
            PARTITION BY co.Name
            ORDER BY SUM(oli.TotalPrice) DESC
        ) AS rn
    FROM Customer c
    INNER JOIN AccountTier at ON c.AccountTierID = at.ID
    INNER JOIN Territory t ON c.TerritoryID = t.ID
    INNER JOIN Country co ON t.CountryID = co.ID
    INNER JOIN SaleOrder o ON c.ID = o.CustomerID
    INNER JOIN OrderLineItem oli ON o.ID = oli.SaleOrderID
    WHERE YEAR(o.OrderDate) = YEAR(GETDATE())
    GROUP BY 
        c.ID,
        c.Name,
        co.Name,
        at.Name
) ranked_customers
WHERE rn = 1;

--6.Finds products that have never been sold in regions generating more than €1M revenue in the past year using a correlated subquery
WITH high_revenue_regions AS (
    SELECT r.ID AS RegionID
    FROM Region r
    JOIN Country co ON r.ID = co.RegionID
    JOIN Territory t ON co.ID = t.CountryID
    JOIN Customer c ON t.ID = c.TerritoryID
    JOIN SaleOrder o ON c.ID = o.CustomerID
    JOIN OrderLineItem oli ON o.ID = oli.SaleOrderID
    WHERE o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY r.ID
    HAVING SUM(oli.TotalPrice) > 1000000
)
SELECT 
    p.ID AS ProductID,
    p.Name AS ProductName
FROM Product p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderLineItem oli
    INNER JOIN SaleOrder o ON oli.SaleOrderID = o.ID
    INNER JOIN Customer c ON o.CustomerID = c.ID
    INNER JOIN Territory t ON c.TerritoryID = t.ID
    INNER JOIN Country co ON t.CountryID = co.ID
    WHERE oli.ProductID = p.ID AND co.RegionID IN (
          SELECT RegionID 
          FROM high_revenue_regions
      )
      AND o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
);
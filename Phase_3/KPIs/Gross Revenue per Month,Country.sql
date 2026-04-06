--Gross Revenue per Month,Country
SELECT 
    d.Year,
    d.MonthNum,
    ctry.Name AS Country,
    SUM(oli.Quantity * p.ListingPrice) AS GrossRevenue
FROM OrderLineItem oli
INNER JOIN SaleOrder so ON oli.SaleOrderID = so.ID
INNER JOIN Customer c ON so.CustomerID = c.ID
INNER JOIN Territory t on t.ID = c.TerritoryID
INNER JOIN Country ctry ON ctry.ID = t.CountryID
INNER JOIN Product p ON oli.ProductID = p.ID
INNER JOIN Date d ON so.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNum, ctry.Name
Order by d.Year,d.MonthNum;


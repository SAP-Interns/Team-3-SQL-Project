--Gross Revenue per Month,Country
SELECT 
    d.Year,
    d.MonthNum,
    ctry.Name AS Country,
    SUM(oli.Quantity * p.ListingPrice) AS GrossRevenue
FROM OrderLineItem oli
JOIN SaleOrder so ON oli.SaleOrderID = so.ID
JOIN Customer c ON so.CustomerID = c.ID
JOIN Country ctry ON c.CountryID = ctry.ID
JOIN Product p ON oli.ProductID = p.ID
JOIN Date d ON so.OrderDate = d.FullDate
GROUP BY d.Year, d.MonthNum, ctry.Name
Order by d.Year,d.MonthNum;
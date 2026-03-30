DECLARE @QueryNum INT = 5

	IF @QueryNum = 1
	BEGIN
		DECLARE @Tier NVARCHAR(50) = '%Gold%'
		DECLARE @CreditLimit INT = 50000
		SELECT 
		C.Name AS Customer,
		C.BillingAddress,
		C.CreditLimit,
		A.Name AS AccountTier 
		FROM Customer C
		INNER JOIN AccountTier A ON A.ID = C.AccountTierID
		WHERE A.Name LIKE @Tier AND C.CreditLimit > @CreditLimit
		ORDER BY CreditLimit DESC
	END

	IF @QueryNum = 2
	BEGIN
		SELECT 
		C.Name AS CustomerName,
		S.OrderDate,
		SUM(O.TotalPrice) AS TotalValue
		FROM SaleOrder S
		INNER JOIN SaleStatus SS ON SS.ID = S.SaleStatusID
		INNER JOIN Date D ON D.DateKey = S.OrderDateKey
		INNER JOIN Customer C ON C.ID = S.CustomerID
		INNER JOIN OrderLineItem O ON O.SaleOrderID = S.ID
		WHERE SS.Name LIKE '%Pending%' AND D.Year = YEAR(GETDATE()) -1 AND D.Quarter = 3
		GROUP BY C.Name, S.OrderDate
	END

	IF @QueryNum = 3
	BEGIN
		SELECT
		P.Name AS ProductName,
		C.Name AS CategoryName,
		P.UnitCost,
		P.ListingPrice,
		CAST(ROUND(T.Margin, 2) AS NVARCHAR(50)) + '%' AS 'Gross Margin'
		FROM
		(
			SELECT
			P.ID,
			(1-(P.UnitCost / P.ListingPrice)) * 100 AS Margin
			FROM Product P
		) AS T
		INNER JOIN Product P ON P.ID = T.ID
		INNER JOIN Category C ON C.ID = P.CategoryID
		WHERE T.Margin > 66
		ORDER BY T.Margin DESC
	END

	IF @QueryNum = 4
	BEGIN
		SELECT 
		SP.Name AS SalesRepName,
		R.Name AS Region,
		SP.StartingDate
		FROM SalesRepresentative SP
		INNER JOIN Region R ON R.ID = SP.RegionID
		WHERE SP.ID NOT IN 
		(
			SELECT 
			SalesRepresentativeID
			FROM Customer_SalesRepresentative CS
			INNER JOIN Date D ON D.DateKey = CS.AssignedDateKey
			WHERE D.FullDate >= DATEADD(month, -6, GETDATE())
		)
	END

	IF @QueryNum = 5
	BEGIN
		DECLARE @ShippingDateDifference INT = 14
		DECLARE @Country NVARCHAR(100) = '%Austria%'
		SELECT 
		C.Name AS Customer,
		CC.Name AS Country,
		SUM(O.TotalPrice) AS Price,
		S.OrderDate,
		S.ShippingDate,
		DATEDIFF(DAY, S.OrderDate, S.ShippingDate) AS DateDifference
		FROM SaleOrder S
		INNER JOIN OrderLineItem O ON O.SaleOrderID = S.ID
		INNER JOIN [Product] P ON P.ID = O.ProductID
		INNER JOIN Customer C ON C.ID = S.CustomerID
		INNER JOIN Country CC ON CC.ID = C.CountryID
		WHERE DATEDIFF(DAY, S.OrderDate, S.ShippingDate) > @ShippingDateDifference AND CC.Name LIKE @Country
		GROUP BY C.Name,CC.Name,S.OrderDate,S.ShippingDate
	END

	IF @QueryNum = 6
	BEGIN
		SELECT 
		P.Name,
		C.Name AS Category,
		P.UnitCost,
		P.ListingPrice,
		P.Stock FROM Product P
		INNER JOIN Category C ON C.ID = P.CategoryID
		WHERE P.Name LIKE '%Pro' OR P.Name LIKE '%Max%' OR P.Name LIKE '%Plus%'
	END

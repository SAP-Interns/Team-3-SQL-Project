DECLARE @QueryNum INT = 4

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
		C.Name AS CustomerName,
		P.UnitCost,
		P.ListingPrice
		FROM Product P
		INNER JOIN Category C ON C.ID = P.CategoryID
		WHERE P.ListingPrice >= (3 * P.UnitCost)
	END

	IF @QueryNum = 4
	BEGIN
		SELECT 
		SP.Name AS SalesRepName,
		C.Name AS CustomerName,
		SP.StartingDate
		FROM SalesRepresentative SP
		INNER JOIN Region R ON R.ID = SP.RegionID
		INNER JOIN Country C ON C.RegionID = R.ID
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
		P.Name AS Product,
		O.TotalPrice,
		S.OrderDate,
		S.ShippingDate 
		FROM SaleOrder S
		INNER JOIN OrderLineItem O ON O.SaleOrderID = S.ID
		INNER JOIN [Product] P ON P.ID = O.ProductID
		INNER JOIN Customer C ON C.ID = S.CustomerID
		INNER JOIN Country CC ON CC.ID = C.CountryID
		WHERE DATEDIFF(DAY, S.OrderDate, S.ShippingDate) > @ShippingDateDifference AND CC.Name LIKE @Country
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
		WHERE P.Name LIKE '%Pro' OR P.Name LIKE '%Max%' OR P.Name LIKE '%Ultra%'
	END

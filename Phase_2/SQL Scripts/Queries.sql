DECLARE @QueryNum INT = 5

	IF @QueryNum = 1
	/*List all customers in Germany whose account tier is Gold and whose credit limit exceeds
	50,000, ordered by credit limit descending.*/
	BEGIN
		DECLARE @Tier NVARCHAR(50) = '%Gold%'
		DECLARE @CreditLimit INT = 50000
		SELECT 
		C.Name AS Customer,
		C.BillingAddress,
		C.CreditLimit,
		A.Name AS AccountTier 
		FROM dim_customers C
		INNER JOIN dim_account_tiers A ON A.ID = C.AccountTierID
		INNER JOIN dim_territories T ON T.ID = C.TerritoryID
		INNER JOIN dim_countries CC ON CC.ID = T.CountryID
		WHERE A.Name LIKE @Tier AND C.CreditLimit > @CreditLimit AND CC.Name LIKE '%Germany%'
		ORDER BY CreditLimit DESC
	END

	IF @QueryNum = 2
	/*Retrieve all sales orders placed in Q3 of the most recent complete year that have a status of
	Pending or Partially Delivered, showing the customer name, order date, and total value. */
	BEGIN
		SELECT 
		C.Name AS CustomerName,
		S.OrderDate,
		SUM(O.TotalPrice) AS TotalValue
		FROM fact_sale_orders S
		INNER JOIN dim_sale_statuses SS ON SS.ID = S.SaleStatusID
		INNER JOIN dim_date D ON D.DateKey = S.OrderDateKey
		INNER JOIN dim_customers C ON C.ID = S.CustomerID
		INNER JOIN fact_order_line_items O ON O.SaleOrderID = S.ID
		WHERE SS.Name LIKE '%Pending%' OR SS.Name LIKE '%Partially Delivered%' AND D.Year = YEAR(GETDATE()) -1 AND D.Quarter = 3
		GROUP BY C.Name, S.OrderDate
	END

	IF @QueryNum = 3
	/*Find all products whose list price is more than three times their unit cost (i.e., gross margin
	above 66%), ordered by margin descending.*/
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
			FROM dim_products P
		) AS T
		INNER JOIN dim_products P ON P.ID = T.ID
		INNER JOIN dim_categories C ON C.ID = P.CategoryID
		WHERE T.Margin > 66
		ORDER BY T.Margin DESC
	END

	IF @QueryNum = 4
	/*Identify all sales representatives who have not been assigned to any customer territory in the
	last 6 months, using appropriate NULL-awareness in your filter. */
	BEGIN
		SELECT 
		SP.Name AS SalesRepName,
		R.Name AS Region,
		SP.StartingDate
		FROM dim_sales_reps SP
		INNER JOIN dim_regions R ON R.ID = SP.RegionID
		WHERE NOT EXISTS (
			SELECT 1
			FROM rep_customer_assignments CS
			INNER JOIN dim_date D ON D.DateKey = CS.AssignedDateKey
			WHERE D.FullDate >= DATEADD(month, -6, GETDATE()) AND CS.IsActive = 1 AND CS.SalesRepresentativeID = SP.ID
		)
	END

	IF @QueryNum = 5
	/* List all orders where the shipping date is more than 14 days after the order date, indicating a
	delivery delay, filtered by a specific country of your choice.  */
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
		FROM fact_sale_orders S
		INNER JOIN fact_order_line_items O ON O.SaleOrderID = S.ID
		INNER JOIN dim_products P ON P.ID = O.ProductID
		INNER JOIN dim_customers C ON C.ID = S.CustomerID
		INNER JOIN dim_territories T ON T.ID = C.TerritoryID
		INNER JOIN dim_countries CC ON CC.ID = T.CountryID
		WHERE S.ShippingDate > DATEADD(DAY, 14, S.OrderDate) AND CC.Name LIKE @Country
		GROUP BY C.Name,CC.Name,S.OrderDate,S.ShippingDate
	END

	IF @QueryNum = 6
	/*Find all products where the product name contains the word Pro,Plus, or Max, regardless of case.*/
	BEGIN
		SELECT 
		P.Name,
		C.Name AS Category,
		P.UnitCost,
		P.ListingPrice,
		P.Stock FROM dim_products P
		INNER JOIN dim_categories C ON C.ID = P.CategoryID
		WHERE P.Name LIKE '%Pro%' OR P.Name LIKE '%Max%' OR P.Name LIKE '%Plus%'
	END
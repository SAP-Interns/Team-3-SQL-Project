DECLARE @QueryNum INT = 2

	IF @QueryNum = 1
	/*Full Order Summary: Write a query that joins orders, line items, customers, products, regions,
	and sales reps into a single result set, producing a complete order line record with all business-
	relevant attributes. This query will form the foundation of the reporting layer.*/
	BEGIN
		SELECT
		SO.ID AS OrderID,
		SO.OrderDate,
		C.Name AS 'Customer Name',
		SR.Name AS 'Sales Rep',
		R.Name AS 'Region',
		CASE
			WHEN MAX(O.PromotionID) IS NULL THEN 'Not on Promotion'
			ELSE 'On Promotion'
		END AS Promotion,
		CASE
			WHEN SO.ShippingDate IS NULL THEN 'Not Delivered'
			ELSE CAST(SO.ShippingDate AS NVARCHAR(50))
		END AS 'Shipping Date',
		SUM(O.TotalPrice) AS 'Total Price',
		SS.Name AS 'Status'
		FROM SaleOrder SO
		INNER JOIN OrderLineItem O ON O.SaleOrderID = SO.ID
		INNER JOIN Customer C ON C.ID = SO.CustomerID
		INNER JOIN SalesRepresentative SR ON SR.ID = SO.SalesRepresentativeID
		INNER JOIN Product P ON P.ID = O.ProductID
		INNER JOIN Territory T ON T.ID = C.TerritoryID
		INNER JOIN Country CC ON CC.ID = T.CountryID
		INNER JOIN Region R ON R.ID = CC.RegionID
		INNER JOIN SaleStatus SS ON SS.ID = SO.SaleStatusID
		LEFT JOIN Promotion PR ON PR.ID = O.PromotionID
		GROUP BY SO.ID,SO.OrderDate, C.Name, SR.Name, R.Name, SO.ShippingDate, SS.Name
	END

	IF @QueryNum = 2
	/*Orphan Detection: Using LEFT JOIN, identify any customer records that exist in dim_customers
	but have never placed an order. These are dormant accounts that require a sales follow-up. */
	BEGIN
		SELECT 
		DISTINCT(C.ID) AS CustomerID,
		C.Name AS 'Customer Name'
		FROM Customer C
		LEFT JOIN SaleOrder SO ON SO.CustomerID = C.ID
		WHERE SO.CustomerID IS NULL
	END

	IF @QueryNum = 3
	/*Rep-Customer Mismatch: Identify all orders where the sales rep who processed the order is not
	the assigned rep for that customer account according to the rep_customer_assignments table.*/
	BEGIN
		SELECT
		SO.ID AS OrderID,
		SR.Name AS 'Sales Rep',
		C.Name AS 'Customer Name',
		SO.OrderDate
		FROM SaleOrder SO
		INNER JOIN SalesRepresentative SR ON SR.ID = SO.SalesRepresentativeID
		INNER JOIN Customer C ON C.ID = SO.CustomerID
		LEFT JOIN Customer_SalesRepresentative CSR ON CSR.SalesRepresentativeID = SR.ID AND CSR.CustomerID = C.ID
		WHERE CSR.SalesRepresentativeID IS NULL
	END

	IF @QueryNum = 4
	/*Revenue by Geography: Join orders, customers, and regions to produce a complete revenue
	breakdown at Country  Region  Territory level, including subtotals. */
	BEGIN
		SELECT 'NOT DONE'
	END

	IF @QueryNum = 5
	/* Product Cost vs. Actual Sell Price: Join order line items with products to compute the realized
	margin on every line item, comparing the actual sell price (after discount) against the product&#39;s
	unit cost.*/
	BEGIN
		SELECT 'NOT DONE'
	END

	IF @QueryNum = 6
	/*Unordered Products: Identify all active products that appear in dim_products but have not
	appeared in any order line item in the last 12 months. These are candidates for discontinuation.*/
	BEGIN
		SELECT 'NOT DONE'
	END

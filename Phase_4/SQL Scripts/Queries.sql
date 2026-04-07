DECLARE @QueryNum INT = 1

	IF @QueryNum = 1
	/*Full Order Summary: Write a query that joins orders, line items, customers, products, regions,
	and sales reps into a single result set, producing a complete order line record with all business-
	relevant attributes. This query will form the foundation of the reporting layer.*/
	BEGIN
		SELECT
		SO.ID AS SaleOrderID,
		SO.OrderDate,
		C.Name AS 'Customer Name',
		SR.Name AS 'Sales Rep',
		R.Name AS 'Region',
		CC.Name AS Country,
		T.Name AS Territory,
		CASE
			WHEN O.PromotionID IS NULL THEN 'Not on Promotion'
			ELSE 'On Promotion'
		END AS Promotion,
		CASE
			WHEN SO.ShippingDate IS NULL THEN 'Not Delivered'
			ELSE CAST(SO.ShippingDate AS NVARCHAR(50))
		END AS 'Shipping Date',
		P.Name AS Product,
		P.UnitCost,
		O.Quantity,
		O.UnitPrice,
		O.TotalPrice,
		SS.Name AS 'Status'
		FROM OrderLineItem O
		INNER JOIN SaleOrder SO ON SO.ID = O.SaleOrderID
		INNER JOIN Customer C ON C.ID = SO.CustomerID
		INNER JOIN SalesRepresentative SR ON SR.ID = SO.SalesRepresentativeID
		INNER JOIN Product P ON P.ID = O.ProductID
		INNER JOIN Territory T ON T.ID = C.TerritoryID
		INNER JOIN Country CC ON CC.ID = T.CountryID
		INNER JOIN Region R ON R.ID = CC.RegionID
		INNER JOIN SaleStatus SS ON SS.ID = SO.SaleStatusID
		LEFT JOIN Promotion PR ON PR.ID = O.PromotionID
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
		FROM Customer_SalesRepresentative CSR
		INNER JOIN SalesRepresentative SR ON SR.ID = CSR.SalesRepresentativeID
		INNER JOIN Customer C ON C.ID = CSR.CustomerID
		LEFT JOIN SaleOrder SO ON SO.SalesRepresentativeID = CSR.SalesRepresentativeID AND SO.CustomerID = CSR.CustomerID
		WHERE CSR.SalesRepresentativeID IS NULL
	END

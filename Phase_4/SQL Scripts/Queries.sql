DECLARE @QueryNum INT = 5

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
		FROM fact_order_line_items O
		INNER JOIN fact_sale_orders SO ON SO.ID = O.SaleOrderID
		INNER JOIN dim_customers C ON C.ID = SO.CustomerID
		INNER JOIN dim_sales_reps SR ON SR.ID = SO.SalesRepresentativeID
		INNER JOIN dim_products P ON P.ID = O.ProductID
		INNER JOIN dim_territories T ON T.ID = C.TerritoryID
		INNER JOIN dim_countries CC ON CC.ID = T.CountryID
		INNER JOIN dim_regions R ON R.ID = CC.RegionID
		INNER JOIN dim_sale_statuses SS ON SS.ID = SO.SaleStatusID
		LEFT JOIN dim_promotions PR ON PR.ID = O.PromotionID
	END

	IF @QueryNum = 2
	/*Orphan Detection: Using LEFT JOIN, identify any customer records that exist in dim_customers
	but have never placed an order. These are dormant accounts that require a sales follow-up. */
	BEGIN
		SELECT 
		DISTINCT(C.ID) AS CustomerID,
		C.Name AS 'Customer Name'
		FROM dim_customers C
		LEFT JOIN fact_sale_orders SO ON SO.CustomerID = C.ID
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
		FROM rep_customer_assignments CSR
		INNER JOIN dim_sales_reps SR ON SR.ID = CSR.SalesRepresentativeID
		INNER JOIN dim_customers C ON C.ID = CSR.CustomerID
		LEFT JOIN fact_sale_orders SO ON SO.SalesRepresentativeID = CSR.SalesRepresentativeID AND SO.CustomerID = CSR.CustomerID
		WHERE CSR.SalesRepresentativeID IS NULL
	END

	IF @QueryNum = 4
	/*Revenue by Geography: Join orders, customers, and regions to produce a complete revenue
	breakdown at Country , Region including subtotals.*/
	BEGIN
		SELECT 
			r.name AS region,
			c.name AS country,
			t.name as territory,
			ROUND(SUM(oli.totalprice), 2) AS total_revenue
		FROM fact_sale_orders so
		JOIN fact_order_line_items oli ON so.id = oli.saleorderid
		JOIN dim_customers cust ON so.customerid = cust.id
		INNER JOIN dim_territories t on t.ID = cust.TerritoryID
		JOIN dim_countries c ON c.ID = t.CountryID
		JOIN dim_regions r ON c.regionid = r.id
		GROUP BY 
			ROLLUP (r.name, c.name,t.name)
		ORDER BY 
			r.name, c.name;
	END

	IF @QueryNum = 5
	/*Product Cost vs. Actual Sell Price: Join order line items with products to compute the realized
	margin on every line item, comparing the actual sell price (after discount) against the products
	unit cost*/
	BEGIN
		SELECT 
			oli.id AS order_line_id,
			p.name AS product_name,
			oli.quantity,
			p.unitcost,
			oli.unitprice,
			COALESCE(pr.discountpercentage, 0) AS discount_percentage,
			oli.unitprice * (1 - COALESCE(pr.discountpercentage, 0) / 100.0) AS actual_sell_price,
			(oli.unitprice * (1 - COALESCE(pr.discountpercentage, 0) / 100.0) - p.unitcost) AS margin_per_unit,
			((oli.unitprice * (1 - COALESCE(pr.discountpercentage, 0) / 100.0) - p.unitcost) * oli.quantity) AS total_margin
		FROM fact_order_line_items oli
		JOIN dim_products p ON oli.productid = p.id
		LEFT JOIN dim_promotions pr ON oli.promotionid = pr.id;		
	END

	IF @QueryNum = 6
	/*Unordered Products: Identify all active products that appear in dim_products but have not
	appeared in any order line item in the last 12 months. These are candidates for discontinuation.*/
	BEGIN
		SELECT 
			p.id,
			p.name,
			p.listingprice,
			p.unitcost,
			p.stock
		FROM dim_products p
		WHERE NOT EXISTS (
			SELECT 1
			FROM fact_order_line_items oli
			JOIN fact_sale_orders so ON oli.saleorderid = so.id
			WHERE oli.productid = p.id
			  AND so.orderdate >= DATEADD(MONTH, -12, GETDATE())
		);		
	END


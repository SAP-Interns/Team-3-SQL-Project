--Revenue by Geography: Join orders, customers, and regions to produce a complete revenue
--breakdown at Country → Region including subtotals.
SELECT 
    r.name AS region,
    c.name AS country,
    SUM(oli.totalprice) AS total_revenue
FROM SaleOrder so
JOIN OrderLineItem oli ON so.id = oli.saleorderid
JOIN Customer cust ON so.customerid = cust.id
JOIN Country c ON cust.countryid = c.id
JOIN Region r ON c.regionid = r.id
GROUP BY 
    ROLLUP (r.name, c.name)
ORDER BY 
    r.name, c.name;

--Product Cost vs. Actual Sell Price: Join order line items with products to compute the realized
--margin on every line item, comparing the actual sell price (after discount) against the products
--unit cost.
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
FROM OrderLineItem oli
JOIN Product p ON oli.productid = p.id
LEFT JOIN Promotion pr ON oli.promotionid = pr.id;

--Unordered Products: Identify all active products that appear in dim_products but have not
--appeared in any order line item in the last 12 months. These are candidates for discontinuation.
SELECT 
    p.id,
    p.name,
    p.listingprice,
    p.unitcost,
    p.stock
FROM Product p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderLineItem oli
    JOIN SaleOrder so ON oli.saleorderid = so.id
    WHERE oli.productid = p.id
      AND so.orderdate >= DATEADD(MONTH, -12, GETDATE())
);
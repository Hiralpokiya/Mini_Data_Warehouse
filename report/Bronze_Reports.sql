--Report 1 — Customer Overview
SELECT 
    cst_id,
    cst_key,
    cst_firstname || ' ' || cst_lastname  AS full_name,
    cst_email,
    cst_phone,
    cst_status,
    cst_create_date::DATE                 AS joined_date
FROM bronze.api_customers
ORDER BY cst_id;

--Report 2 — Active vs Inactive Customers

SELECT 
    cst_status,
    COUNT(*)                              AS total_customers,
    ROUND(COUNT(*) * 100.0 / 
          SUM(COUNT(*)) OVER(), 2)        AS percentage
FROM bronze.api_customers
GROUP BY cst_status
ORDER BY total_customers DESC;

--Report 3 — Customers with Their Orders

SELECT 
    c.cst_firstname || ' ' || c.cst_lastname  AS customer_name,
    c.cst_email,
    c.cst_status,
    COUNT(o.ord_id)                            AS total_orders,
    ROUND(SUM(o.ord_total_amount)::NUMERIC, 2) AS total_spent,
    ROUND(AVG(o.ord_total_amount)::NUMERIC, 2) AS avg_order_value,
    MAX(o.ord_date::DATE)                      AS last_order_date
FROM bronze.api_customers c
LEFT JOIN bronze.api_orders o ON o.ord_cust_id = c.cst_id
GROUP BY c.cst_id, c.cst_firstname, c.cst_lastname, 
         c.cst_email, c.cst_status
ORDER BY total_spent DESC NULLS LAST;

--Report 4 — Top 10 Customers by Revenue
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(o.ord_total_amount) DESC) AS rank,
    c.cst_firstname || ' ' || c.cst_lastname  AS customer_name,
    c.cst_email,
    COUNT(o.ord_id)                            AS total_orders,
    SUM(o.ord_quantity)                        AS total_items,
    ROUND(SUM(o.ord_total_amount)::NUMERIC, 2) AS total_spent
FROM bronze.api_customers c
JOIN bronze.api_orders o ON o.ord_cust_id = c.cst_id
WHERE o.ord_status = 'Completed'
GROUP BY c.cst_id, c.cst_firstname, c.cst_lastname, c.cst_email
ORDER BY total_spent DESC
LIMIT 10;

--Report 5 — Customer Orders with Product Details

SELECT 
    c.cst_firstname || ' ' || c.cst_lastname  AS customer_name,
    c.cst_email,
    o.ord_key                                  AS order_number,
    p.prd_name                                 AS product,
    p.prd_category                             AS category,
    o.ord_quantity                             AS qty,
    o.ord_unit_price                           AS unit_price,
    o.ord_total_amount                         AS total,
    o.ord_status                               AS status,
    o.ord_date::DATE                           AS order_date,
    o.ord_ship_date::DATE                      AS ship_date
FROM bronze.api_customers c
JOIN bronze.api_orders  o ON o.ord_cust_id = c.cst_id
JOIN bronze.api_products p ON p.prd_id     = o.ord_prd_id
ORDER BY o.ord_date DESC;

--Report 6 — Monthly New Customer Signups

SELECT 
    TO_CHAR(cst_create_date::DATE, 'YYYY-MM')  AS month,
    COUNT(*)                                    AS new_customers,
    COUNT(*) FILTER (WHERE cst_status = 'Active')   AS active,
    COUNT(*) FILTER (WHERE cst_status = 'Inactive') AS inactive
FROM bronze.api_customers
GROUP BY TO_CHAR(cst_create_date::DATE, 'YYYY-MM')
ORDER BY month;

--Report 7 — Revenue by Product Category per Customer

SELECT 
    p.prd_category                             AS category,
    COUNT(DISTINCT c.cst_id)                   AS unique_customers,
    COUNT(o.ord_id)                            AS total_orders,
    SUM(o.ord_quantity)                        AS units_sold,
    ROUND(SUM(o.ord_total_amount)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(o.ord_total_amount)::NUMERIC, 2) AS avg_order_value
FROM bronze.api_customers c
JOIN bronze.api_orders   o ON o.ord_cust_id = c.cst_id
JOIN bronze.api_products p ON p.prd_id      = o.ord_prd_id
WHERE o.ord_status = 'Completed'
GROUP BY p.prd_category
ORDER BY total_revenue DESC;

--Report 8 — Customers Who Never Ordered

SELECT 
    cst_id,
    cst_firstname || ' ' || cst_lastname  AS customer_name,
    cst_email,
    cst_status,
    cst_create_date::DATE                 AS joined_date
FROM bronze.api_customers
WHERE cst_id NOT IN (
    SELECT DISTINCT ord_cust_id 
    FROM bronze.api_orders
)
ORDER BY cst_create_date;
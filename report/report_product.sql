-- ============================================
-- Product Analysis Report
-- ============================================

-- Sales by product category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity)     AS total_quantity
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;

-- Top 10 best selling products
SELECT
    p.product_name,
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity)     AS total_quantity
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY total_sales DESC
LIMIT 10;

-- Products with no sales
SELECT
    p.product_name,
    p.category
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f ON p.product_key = f.product_key
WHERE f.product_key IS NULL;
-- ============================================
-- Sales Analysis Report
-- ============================================

-- Monthly sales trend
SELECT
    DATE_TRUNC('month', order_date) AS sales_month,
    SUM(sales_amount)               AS total_sales,
    COUNT(order_number)             AS total_orders,
    SUM(quantity)                   AS total_quantity
FROM gold.fact_sales
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month;

-- Yearly sales summary
SELECT
    EXTRACT(YEAR FROM order_date) AS sales_year,
    SUM(sales_amount)             AS total_sales,
    COUNT(order_number)           AS total_orders
FROM gold.fact_sales
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY sales_year;

-- Average order value
SELECT
    ROUND(AVG(sales_amount), 2) AS avg_order_value,
    MAX(sales_amount)           AS max_order_value,
    MIN(sales_amount)           AS min_order_value
FROM gold.fact_sales;
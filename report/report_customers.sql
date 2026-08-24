-- ============================================
-- Customer Analysis Report
-- ============================================

-- Customer count by country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customer count by gender
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender;

-- Customer count by marital status
SELECT
    marital_status,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY marital_status;

-- Top 10 customers by total sales
SELECT
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    SUM(f.sales_amount)                AS total_sales,
    COUNT(f.order_number)              AS total_orders
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.first_name, c.last_name, c.country
ORDER BY total_sales DESC
LIMIT 10;
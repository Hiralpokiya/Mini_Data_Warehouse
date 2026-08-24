/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), EXTRACT(), AGE()
===============================================================================
*/

-- 1. Explore all countries our customers come from and determine the sales data range.
-- How many years of sales are available?
SELECT 
    'Sales Date Range' AS analysis,
    MIN(order_date)::text AS value_1,
    MAX(order_date)::text AS value_2,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date)))::text AS value_3,
    AGE(MAX(order_date), MIN(order_date))::text AS value_4
FROM gold.fact_sales

UNION ALL

SELECT 
    'Customer Age Range' AS analysis,
    MIN(birth_date)::text AS value_1,
    EXTRACT(YEAR FROM AGE(NOW(), MIN(birth_date)))::text AS value_2,
    MAX(birth_date)::text AS value_3,
    EXTRACT(YEAR FROM AGE(NOW(), MAX(birth_date)))::text AS value_4
FROM gold.dim_customers;
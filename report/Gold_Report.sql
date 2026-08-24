-- Check all gold tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'gold'
ORDER BY table_name;

-- Row counts for all gold tables
SELECT 'api_dim_customers' AS tbl, COUNT(*) FROM gold.api_dim_customers
UNION ALL
SELECT 'api_dim_products',        COUNT(*) FROM gold.api_dim_products
UNION ALL
SELECT 'api_fact_orders',         COUNT(*) FROM gold.api_fact_orders
UNION ALL
SELECT 'dim_customers',           COUNT(*) FROM gold.dim_customers
UNION ALL
SELECT 'dim_products',            COUNT(*) FROM gold.dim_products
UNION ALL
SELECT 'dim_date',                COUNT(*) FROM gold.dim_date;

-- View gold API data
SELECT * FROM gold.api_dim_customers LIMIT 10;
SELECT * FROM gold.api_dim_products  LIMIT 10;
SELECT * FROM gold.api_fact_orders   LIMIT 10;

-- View gold CSV data
SELECT * FROM gold.dim_customers LIMIT 10;
SELECT * FROM gold.dim_products  LIMIT 10;
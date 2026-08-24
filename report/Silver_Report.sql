-- Check all silver tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'silver'
ORDER BY table_name;

-- Row counts for all silver tables
SELECT 'api_customers'    AS tbl, COUNT(*) FROM silver.api_customers
UNION ALL
SELECT 'crm_cust_info',          COUNT(*) FROM silver.crm_cust_info
UNION ALL
SELECT 'crm_prd_info',           COUNT(*) FROM silver.crm_prd_info
UNION ALL
SELECT 'crm_sales_details',      COUNT(*) FROM silver.crm_sales_details;

-- View silver customer data
SELECT * FROM silver.api_customers LIMIT 10;
SELECT * FROM silver.api_orders LIMIT 10;
SELECT * FROM silver.api_products LIMIT 10;

-- View silver CRM data
SELECT * FROM silver.crm_cust_info    LIMIT 10;
SELECT * FROM silver.crm_prd_info     LIMIT 10;
SELECT * FROM silver.crm_sales_details LIMIT 10;
SELECT 'bronze.crm_cust_info - NULL cst_id' AS check_name,
       COUNT(*) AS issue_count
FROM bronze.crm_cust_info
WHERE cst_id IS NULL

UNION ALL

SELECT 'bronze.crm_cust_info - Duplicate cst_id',
       COUNT(*) - COUNT(DISTINCT cst_id)
FROM bronze.crm_cust_info

UNION ALL

SELECT 'bronze.crm_sales_details - Negative prices',
       COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_price < 0

UNION ALL

SELECT 'silver.crm_cust_info - Invalid gender',
       COUNT(*)
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'Unknown')

UNION ALL

SELECT 'silver.crm_cust_info - Invalid marital status',
       COUNT(*)
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'Unknown')

UNION ALL

SELECT 'silver.crm_sales_details - Order after Ship date',
       COUNT(*)
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt

UNION ALL

SELECT 'silver.erp_cust_az12 - Future birth dates',
       COUNT(*)
FROM silver.erp_cust_az12
WHERE bdate > CURRENT_DATE

UNION ALL

SELECT 'gold.fact_sales - NULL product_key',
       COUNT(*)
FROM gold.fact_sales
WHERE product_key IS NULL

UNION ALL

SELECT 'gold.fact_sales - NULL customer_key',
       COUNT(*)
FROM gold.fact_sales
WHERE customer_key IS NULL

UNION ALL

SELECT 'gold.fact_sales - Sales amount mismatch',
       COUNT(*)
FROM gold.fact_sales
WHERE sales_amount != quantity * price;

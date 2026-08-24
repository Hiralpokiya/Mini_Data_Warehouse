SELECT 
    'Fact: null customer_key'       AS check_name,
    COUNT(*)                        AS issues,
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END AS status
FROM gold.api_fact_orders 
WHERE customer_key IS NULL

UNION ALL

SELECT 
    'Fact: null product_key',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_fact_orders 
WHERE product_key IS NULL

UNION ALL

SELECT 
    'Fact: orphaned customer_key',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_fact_orders f
WHERE NOT EXISTS (
    SELECT 1 FROM gold.api_dim_customers c 
    WHERE c.customer_key = f.customer_key
)

UNION ALL

SELECT 
    'Fact: orphaned product_key',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_fact_orders f
WHERE NOT EXISTS (
    SELECT 1 FROM gold.api_dim_products p 
    WHERE p.product_key = f.product_key
)

UNION ALL

SELECT 
    'Fact: negative amounts',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_fact_orders 
WHERE total_amount < 0

UNION ALL

SELECT 
    'Dim customers: null names',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_dim_customers 
WHERE first_name IS NULL OR last_name IS NULL

UNION ALL

SELECT 
    'Dim customers: duplicate IDs',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM (
    SELECT customer_id FROM gold.api_dim_customers 
    GROUP BY customer_id HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 
    'Dim products: null names',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM gold.api_dim_products 
WHERE product_name IS NULL OR TRIM(product_name) = ''

ORDER BY check_name;
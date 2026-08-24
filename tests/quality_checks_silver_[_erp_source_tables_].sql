/*
===============================================================================
Quality Checks for ERP Source Tables
===============================================================================
Script Purpose:
    Performs quality checks for data consistency, accuracy and standardization
    across ERP bronze tables before and after Silver transformation.

Usage:
    Run each section independently by highlighting and pressing F5 in pgAdmin.
===============================================================================
*/

-- ============================================================================
-- >> ERP Customer Table (erp_cust_az12)
-- ============================================================================

-- Check 1: Find CIDs that do not match any customer in CRM
SELECT
    cid,
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
        ELSE cid
    END AS transformed_cid,
    bdate,
    gen
FROM
    bronze.erp_cust_az12
WHERE
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
        ELSE cid
    END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- -----------------------------------------------------------------------

-- Check 2: Find invalid birth dates (too old or future dates)
SELECT
    bdate,
    gen
FROM
    bronze.erp_cust_az12
WHERE
    bdate < '1924-02-01'
    OR bdate > CURRENT_DATE;

-- -----------------------------------------------------------------------

-- Check 3: Show how gender values will be standardized
SELECT DISTINCT
    gen                            AS original_gen,
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
        ELSE 'Unknown'
    END                            AS standardized_gen
FROM
    bronze.erp_cust_az12
ORDER BY original_gen;

-- ============================================================================
-- >> ERP Location Table (erp_loc_a101)
-- ============================================================================

-- Check 4: Find location CIDs that do not match any CRM customer
SELECT
    cid                        AS original_cid,
    REPLACE(cid, '-', '')      AS cleaned_cid,
    cntry
FROM
    bronze.erp_loc_a101
WHERE
    REPLACE(cid, '-', '') NOT IN (
        SELECT cst_key FROM silver.crm_cust_info
    );

-- -----------------------------------------------------------------------

-- Check 5: Show how country values will be standardized
SELECT DISTINCT
    cntry                          AS original_cntry,
    CASE
        WHEN UPPER(TRIM(cntry)) IN (
            'USA', 'US', 'UNITED STATES', 'UNITED STATUS'
        )                          THEN 'United States'
        WHEN UPPER(TRIM(cntry)) = 'DE'     THEN 'Germany'
        WHEN TRIM(cntry) IS NULL
          OR TRIM(cntry) = ''      THEN 'Unknown'
        ELSE TRIM(cntry)
    END                            AS standardized_cntry
FROM
    bronze.erp_loc_a101
ORDER BY original_cntry;

-- ============================================================================
-- >> ERP Product Category Table (erp_px_cat_g1v2)
-- ============================================================================

-- Check 6: Find rows with unwanted leading or trailing spaces
SELECT DISTINCT
    cat,
    subcat,
    maintenance
FROM
    bronze.erp_px_cat_g1v2
WHERE
    cat         != TRIM(cat)
    OR subcat   != TRIM(subcat)
    OR maintenance != TRIM(maintenance);

-- -----------------------------------------------------------------------

-- Check 7: See all distinct category values
SELECT DISTINCT
    cat,
    subcat,
    maintenance
FROM
    bronze.erp_px_cat_g1v2
ORDER BY cat, subcat;

-- ============================================================================
-- >> COMBINED SUMMARY CHECK (Run this to get all counts in one table)
-- ============================================================================

SELECT
    'erp_cust_az12 - CIDs not in CRM'          AS check_name,
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END       AS status,
    COUNT(*)                                    AS issue_count
FROM bronze.erp_cust_az12
WHERE
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
        ELSE cid
    END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

UNION ALL

SELECT
    'erp_cust_az12 - Invalid birth dates',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_cust_az12
WHERE bdate < '1924-02-01'
   OR bdate > CURRENT_DATE

UNION ALL

SELECT
    'erp_cust_az12 - Invalid gender values',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_cust_az12
WHERE UPPER(TRIM(gen)) NOT IN ('F', 'FEMALE', 'M', 'MALE')
  AND gen IS NOT NULL

UNION ALL

SELECT
    'erp_loc_a101 - CIDs not in CRM',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (
    SELECT cst_key FROM silver.crm_cust_info
)

UNION ALL

SELECT
    'erp_loc_a101 - Unexpected country values',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_loc_a101
WHERE UPPER(TRIM(cntry)) NOT IN (
    'USA', 'US', 'UNITED STATES', 'UNITED STATUS',
    'DE', 'GERMANY', 'CANADA', 'AUSTRALIA',
    'FRANCE', 'UNITED KINGDOM', 'UK', ''
)
AND cntry IS NOT NULL

UNION ALL

SELECT
    'erp_px_cat_g1v2 - Unwanted spaces',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_px_cat_g1v2
WHERE cat       != TRIM(cat)
   OR subcat    != TRIM(subcat)
   OR maintenance != TRIM(maintenance)

UNION ALL

SELECT
    'erp_px_cat_g1v2 - Invalid maintenance values',
    CASE WHEN COUNT(*) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END,
    COUNT(*)
FROM bronze.erp_px_cat_g1v2
WHERE maintenance NOT IN ('Yes', 'No')
  AND maintenance IS NOT NULL

ORDER BY check_name;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
/*
===================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the 'silver' schema tables from the 'bronze' schema.

    It performs the following actions:
        - Truncates the silver tables before loading data.
        - Inserts cleaned and transformed data from Bronze into Silver tables.
        - Calculates and displays the time taken for each table load.
        - Calculates and displays the total batch load duration.

Parameters:
    None. This procedure does not accept parameters or return values.

How to use:
    CALL silver.load_silver();

Fixes Applied:
    - Removed ROLLBACK from exception handler (not valid in PostgreSQL procedures)
    - Removed PG_EXCEPTION_DETAIL and PG_EXCEPTION_HINT (not valid in PostgreSQL)
    - Fixed batch_start_time — now set ONCE at top, not inside each table block
    - Fixed typo: 'Singel' → 'Single'
    - Fixed typo: 'Unknow' → 'Unknown' in all places
    - Fixed typo: 'Unkown' → 'Unknown' in erp_loc_a101
    - Fixed typo: 'UNITED STATUS' → 'UNITED STATES'
    - Fixed prd_line: lowercase 's' → UPPER(TRIM()) comparison
===================================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    rows_count       INTEGER;
    start_time       TIMESTAMP;
    end_time         TIMESTAMP;
    interval_diff    INTERVAL;
    hours            INTEGER;
    minutes          INTEGER;
    seconds          INTEGER;
    milliseconds     INTEGER;
    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;
BEGIN

    RAISE NOTICE '==================================================';
    RAISE NOTICE '=========== LOADING SILVER LAYER =================';
    RAISE NOTICE '==================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Starting silver.load_silver procedure';
    RAISE NOTICE '';

    -- Start batch timer ONCE at the top (fixed - was being reset inside each block)
    batch_start_time := NOW();

    -- -------------------------------------------------------------------------
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '------------- Loading CRM Tables ------------------';
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '';
    -- -------------------------------------------------------------------------

    -- >> silver.crm_cust_info
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.crm_cust_info';
    start_time := NOW();
    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname)  AS cst_lastname,
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'   -- Fixed: was 'Singel'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'Unknown'                                               -- Fixed: was 'Unknow'
        END AS cst_marital_status,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'Unknown'                                               -- Fixed: was 'Unknow'
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) AS ranked
    WHERE flag_last = 1; -- Select the most recent record per customer

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_cust_info: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- >> silver.crm_prd_info
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.crm_prd_info';
    start_time := NOW();
    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        sls_prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')    AS cat_id,
        SUBSTRING(prd_key, 7, LENGTH(prd_key))          AS sls_prd_key,
        prd_nm,
        COALESCE(prd_cost, 0)                           AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'    -- Fixed: was lowercase 's', now UPPER handles it
            WHEN 'T' THEN 'Touring'
            ELSE 'Unknown'                 -- Fixed: was 'Unknow'
        END                                             AS prd_line,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1                                           AS prd_end_dt
    FROM
        bronze.crm_prd_info;

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_prd_info: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- >> silver.crm_sales_details
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.crm_sales_details';
    start_time := NOW();
    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt = 0
                 OR LENGTH(CAST(sls_order_dt AS VARCHAR)) != 8 THEN NULL
            ELSE TO_DATE(CAST(sls_order_dt AS VARCHAR), 'YYYYMMDD')
        END AS sls_order_dt,
        CASE
            WHEN sls_ship_dt = 0
                 OR LENGTH(CAST(sls_ship_dt AS VARCHAR)) != 8 THEN NULL
            ELSE TO_DATE(CAST(sls_ship_dt AS VARCHAR), 'YYYYMMDD')
        END AS sls_ship_dt,
        CASE
            WHEN sls_due_dt = 0
                 OR LENGTH(CAST(sls_due_dt AS VARCHAR)) != 8 THEN NULL
            ELSE TO_DATE(CAST(sls_due_dt AS VARCHAR), 'YYYYMMDD')
        END AS sls_due_dt,
        CASE
            WHEN sls_sales IS NULL          THEN ABS(sls_quantity) * ABS(COALESCE(sls_price, 0))
            WHEN sls_sales < 0              THEN ABS(sls_sales)
            WHEN sls_sales = 0              THEN ABS(sls_quantity) * ABS(COALESCE(sls_price, 0))
            WHEN ABS(sls_quantity) * ABS(sls_price) != sls_sales
                                            THEN ABS(sls_quantity) * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales, -- Recalculate if original value is missing or incorrect
        ABS(sls_quantity) AS sls_quantity,
        CASE
            WHEN sls_price IS NULL THEN sls_sales / NULLIF(ABS(sls_quantity), 0)
            WHEN sls_price < 0     THEN ABS(sls_price)
            WHEN sls_price = 0     THEN NULL
            ELSE sls_price
        END AS sls_price -- Derive price if original value is invalid
    FROM
        bronze.crm_sales_details
    WHERE
        sls_order_dt <= sls_ship_dt
        AND sls_order_dt <= sls_due_dt
        AND sls_quantity != 0
        AND sls_price    != 0;

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_sales_details: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- -------------------------------------------------------------------------
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '------------- Loading ERP Tables ------------------';
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '';
    -- -------------------------------------------------------------------------

    -- >> silver.erp_cust_az12
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.erp_cust_az12';
    start_time := NOW();
    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL -- Remove future birth dates
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'Unknown'
        END AS gen
    FROM
        bronze.erp_cust_az12;

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_cust_az12: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- >> silver.erp_loc_a101
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.erp_loc_a101';
    start_time := NOW();
    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN UPPER(TRIM(cntry)) IN ('USA', 'US', 'UNITED STATES') THEN 'United States'  -- Fixed: was 'UNITED STATUS'
            WHEN UPPER(TRIM(cntry)) = 'DE'                            THEN 'Germany'
            WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = ''             THEN 'Unknown'          -- Fixed: was 'Unkown'
            ELSE TRIM(cntry)
        END AS cntry
    FROM
        bronze.erp_loc_a101;

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_loc_a101: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- >> silver.erp_px_cat_g1v2
    RAISE NOTICE '----------';
    RAISE NOTICE '>> Truncate Table and insert into silver.erp_px_cat_g1v2';
    start_time := NOW();
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM
        bronze.erp_px_cat_g1v2;

    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_px_cat_g1v2: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '----------';
    RAISE NOTICE '';

    -- -------------------------------------------------------------------------
    -- Batch complete
    -- -------------------------------------------------------------------------
    batch_end_time := NOW();
    interval_diff  := batch_end_time - batch_start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE 'silver.load_silver procedure completed successfully';
    RAISE NOTICE 'Total Batch Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '';

-- -------------------------------------------------------------------------
-- ERROR HANDLING
-- NOTE: ROLLBACK removed — not valid inside PostgreSQL procedure exception block
-- NOTE: PG_EXCEPTION_DETAIL / PG_EXCEPTION_HINT removed — not valid in PostgreSQL
-- -------------------------------------------------------------------------
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '----------------------------------------------------';
        RAISE NOTICE '---- ERROR OCCURRED DURING LOADING SILVER LAYER ----';
        RAISE NOTICE 'Error Message : %', SQLERRM;
        RAISE NOTICE 'Error Code    : %', SQLSTATE;
        RAISE NOTICE '----------------------------------------------------';
        RAISE NOTICE '';

END;
$BODY$;
/*
===================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external
    CSV files. It performs the following actions:
        - Truncates the bronze tables before loading fresh data.
        - Uses the COPY command to load data from CSV files into bronze tables.
        - Calculates and displays the time taken for each table load.
        - Calculates and displays the total batch load duration.

Parameters:
    None. This procedure does not accept parameters or return values.

How to use:
    CALL bronze.load_bronze();

Fixes Applied:
    - Removed ROLLBACK from exception handler (not valid in PostgreSQL procedures)
    - Removed PG_EXCEPTION_DETAIL and PG_EXCEPTION_HINT (not valid in PostgreSQL)
===================================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
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
    RAISE NOTICE '=========== LOADING BRONZE LAYER =================';
    RAISE NOTICE '==================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Starting bronze.load_bronze procedure';
    RAISE NOTICE '';

    -- Start batch timer here ONCE at the top
    batch_start_time := NOW();

    -- -------------------------------------------------------------------------
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '------------- Loading CRM Tables ------------------';
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '';
    -- -------------------------------------------------------------------------

    -- >> crm_cust_info
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;
    COPY bronze.crm_cust_info
    FROM '/Users/Shared/datasets/source_crm/cust_info.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_cust_info: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '';

    -- >> crm_prd_info
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;
    COPY bronze.crm_prd_info
    FROM '/Users/Shared/datasets/source_crm/prd_info.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_prd_info: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '';

    -- >> crm_sales_details
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;
    COPY bronze.crm_sales_details
    FROM '/Users/Shared/datasets/source_crm/sales_details.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'crm_sales_details: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '';

    -- -------------------------------------------------------------------------
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '------------- Loading ERP Tables ------------------';
    RAISE NOTICE '---------------------------------------------------';
    RAISE NOTICE '';
    -- -------------------------------------------------------------------------

    -- >> erp_cust_az12
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;
    COPY bronze.erp_cust_az12
    FROM '/Users/Shared/datasets/source_erp/CUST_AZ12.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_cust_az12: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '';

    -- >> erp_loc_a101
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;
    COPY bronze.erp_loc_a101
    FROM '/Users/Shared/datasets/source_erp/LOC_A101.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_loc_a101: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
    RAISE NOTICE '';

    -- >> erp_px_cat_g1v2
    start_time := NOW();
    RAISE NOTICE '>> Truncating and loading bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    COPY bronze.erp_px_cat_g1v2
    FROM '/Users/Shared/datasets/source_erp/PX_CAT_G1V2.csv'
    DELIMITER ','
    CSV HEADER;
    GET DIAGNOSTICS rows_count = ROW_COUNT;
    RAISE NOTICE 'erp_px_cat_g1v2: % rows loaded', rows_count;
    end_time     := NOW();
    interval_diff := end_time - start_time;
    hours        := EXTRACT(HOUR        FROM interval_diff);
    minutes      := EXTRACT(MINUTE      FROM interval_diff);
    seconds      := EXTRACT(SECOND      FROM interval_diff)::INTEGER;
    milliseconds := EXTRACT(MILLISECONDS FROM interval_diff)::INTEGER % 1000;
    RAISE NOTICE 'Load Duration: % hours, % minutes, % seconds, % milliseconds', hours, minutes, seconds, milliseconds;
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
    RAISE NOTICE 'bronze.load_bronze procedure completed successfully';
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
        RAISE NOTICE '---- ERROR OCCURRED DURING LOADING BRONZE LAYER ----';
        RAISE NOTICE 'Error Message : %', SQLERRM;
        RAISE NOTICE 'Error Code    : %', SQLSTATE;
        RAISE NOTICE '----------------------------------------------------';
        RAISE NOTICE '';

END;
$BODY$;
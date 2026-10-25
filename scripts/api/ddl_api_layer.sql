/*
===============================================================================
API Layer: Bronze -> Silver -> Gold for the dummyjson.com source
===============================================================================
Run order:
    1. This script (safe to re-run)
    2. python scripts/bronze/load_bronze_api.py     -- fills bronze.api_*
    3. CALL silver.load_api_silver();              -- cleans into silver.api_*
    4. Gold views (gold.api_*) update automatically
===============================================================================
*/
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Bronze: raw data, loaded as-is by the Python API loader
CREATE TABLE IF NOT EXISTS bronze.api_customers (
    cst_id INT, cst_key VARCHAR(20), cst_firstname VARCHAR(100), cst_lastname VARCHAR(100),
    cst_email VARCHAR(200), cst_phone VARCHAR(50), cst_status VARCHAR(20),
    cst_create_date VARCHAR(40)
);
CREATE TABLE IF NOT EXISTS bronze.api_products (
    prd_id INT, prd_key VARCHAR(20), prd_name VARCHAR(255), prd_description TEXT,
    prd_price NUMERIC(10,2), prd_category VARCHAR(100), prd_status VARCHAR(20),
    prd_last_updated TIMESTAMP
);
CREATE TABLE IF NOT EXISTS bronze.api_orders (
    ord_id INT, ord_key VARCHAR(20), ord_cust_id INT, ord_prd_id INT, ord_quantity INT,
    ord_unit_price NUMERIC(10,2), ord_total_amount NUMERIC(12,2), ord_status VARCHAR(20),
    ord_date TIMESTAMP, ord_ship_date TIMESTAMP
);

-- Silver: cleaned and deduplicated
CREATE TABLE IF NOT EXISTS silver.api_customers (
    cst_id INT, cst_key VARCHAR(20), cst_firstname VARCHAR(100), cst_lastname VARCHAR(100),
    cst_email VARCHAR(200), cst_phone VARCHAR(50), cst_status VARCHAR(20), cst_create_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS silver.api_products (
    prd_id INT, prd_key VARCHAR(20), prd_name VARCHAR(255), prd_price NUMERIC(10,2),
    prd_category VARCHAR(100), prd_status VARCHAR(20),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS silver.api_orders (
    ord_id INT, ord_key VARCHAR(20), ord_cust_id INT, ord_prd_id INT, ord_quantity INT,
    ord_unit_price NUMERIC(10,2), ord_total_amount NUMERIC(12,2), ord_status VARCHAR(20),
    ord_date DATE, ord_ship_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE silver.load_api_silver()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Customers: trim names, lowercase emails, one row per id
    TRUNCATE TABLE silver.api_customers;
    INSERT INTO silver.api_customers
        (cst_id, cst_key, cst_firstname, cst_lastname, cst_email, cst_phone, cst_status, cst_create_date)
    SELECT cst_id, cst_key, TRIM(cst_firstname), TRIM(cst_lastname),
           LOWER(TRIM(cst_email)), TRIM(cst_phone),
           COALESCE(NULLIF(TRIM(cst_status), ''), 'Unknown'),
           CASE WHEN cst_create_date ~ '^\d{4}-\d{1,2}-\d{1,2}'
                THEN TO_DATE(SUBSTRING(cst_create_date FROM '^\d{4}-\d{1,2}-\d{1,2}'), 'YYYY-MM-DD')
           END
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_id) AS rn
          FROM bronze.api_customers WHERE cst_id IS NOT NULL) t
    WHERE rn = 1;

    -- Products: trim names, standardize category, no negative prices
    TRUNCATE TABLE silver.api_products;
    INSERT INTO silver.api_products (prd_id, prd_key, prd_name, prd_price, prd_category, prd_status)
    SELECT prd_id, prd_key, TRIM(prd_name), GREATEST(COALESCE(prd_price, 0), 0),
           INITCAP(REPLACE(COALESCE(NULLIF(TRIM(prd_category), ''), 'Uncategorized'), '-', ' ')),
           COALESCE(NULLIF(TRIM(prd_status), ''), 'Unknown')
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY prd_id ORDER BY prd_last_updated DESC) AS rn
          FROM bronze.api_products WHERE prd_id IS NOT NULL) t
    WHERE rn = 1;

    -- Orders: valid quantities only, total recomputed from quantity x price
    TRUNCATE TABLE silver.api_orders;
    INSERT INTO silver.api_orders
        (ord_id, ord_key, ord_cust_id, ord_prd_id, ord_quantity, ord_unit_price,
         ord_total_amount, ord_status, ord_date, ord_ship_date)
    SELECT ord_id, ord_key, ord_cust_id, ord_prd_id, ord_quantity, ord_unit_price,
           ROUND(ord_quantity * ord_unit_price, 2), INITCAP(TRIM(ord_status)),
           ord_date::DATE, ord_ship_date::DATE
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY ord_id ORDER BY ord_id) AS rn
          FROM bronze.api_orders WHERE ord_id IS NOT NULL AND ord_quantity > 0) t
    WHERE rn = 1;

    RAISE NOTICE 'silver.api_* loaded: % customers, % products, % orders',
        (SELECT COUNT(*) FROM silver.api_customers),
        (SELECT COUNT(*) FROM silver.api_products),
        (SELECT COUNT(*) FROM silver.api_orders);
END;
$$;

-- Gold: star schema views read by the dashboard
CREATE OR REPLACE VIEW gold.api_dim_customers AS
SELECT ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
       cst_id AS customer_id, cst_key AS customer_number,
       cst_firstname AS first_name, cst_lastname AS last_name,
       cst_email AS email, cst_status AS status, cst_create_date AS create_date
FROM silver.api_customers;

CREATE OR REPLACE VIEW gold.api_dim_products AS
SELECT ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key,
       prd_id AS product_id, prd_key AS product_number, prd_name AS product_name,
       prd_category AS category, prd_price AS price, prd_status AS status
FROM silver.api_products;

CREATE OR REPLACE VIEW gold.api_fact_orders AS
SELECT o.ord_id AS order_id, o.ord_key AS order_number,
       c.customer_key, p.product_key,
       o.ord_quantity AS quantity, o.ord_unit_price AS unit_price,
       o.ord_total_amount AS total_amount, o.ord_status AS order_status,
       o.ord_date AS order_date, o.ord_ship_date AS ship_date
FROM silver.api_orders o
LEFT JOIN gold.api_dim_customers c ON c.customer_id = o.ord_cust_id
LEFT JOIN gold.api_dim_products  p ON p.product_id  = o.ord_prd_id;

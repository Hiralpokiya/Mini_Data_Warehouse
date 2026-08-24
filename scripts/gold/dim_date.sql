DROP VIEW IF EXISTS gold.dim_date CASCADE;
CREATE VIEW gold.dim_date AS
SELECT
    datum                                    AS date_key,
    EXTRACT(YEAR  FROM datum)::INT           AS year,
    EXTRACT(MONTH FROM datum)::INT           AS month,
    TO_CHAR(datum, 'Month')                  AS month_name,
    EXTRACT(DAY   FROM datum)::INT           AS day,
    EXTRACT(DOW   FROM datum)::INT           AS day_of_week,
    TO_CHAR(datum, 'Day')                    AS day_name,
    EXTRACT(QUARTER FROM datum)::INT         AS quarter,
    'Q' || EXTRACT(QUARTER FROM datum)::INT  AS quarter_name,
    EXTRACT(WEEK FROM datum)::INT            AS week_number,
    CASE
        WHEN EXTRACT(DOW FROM datum) IN (0, 6)
        THEN 'Weekend'
        ELSE 'Weekday'
    END                                      AS day_type
FROM
    GENERATE_SERIES(
        '2000-01-01'::DATE,
        '2030-12-31'::DATE,
        '1 day'::INTERVAL
    ) AS datum;
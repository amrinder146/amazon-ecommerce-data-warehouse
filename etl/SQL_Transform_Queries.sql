-- ============================================================================
-- MBI807B LO1  |  Amazon E-Commerce Data Warehouse  (amazon_bi_dw)
-- ETL PHASE 2 of 3 :  CLEAN & TRANSFORM
-- Profile the raw data, then build the typed, cleaned sales_clean table with
-- parsed dates, casted numbers and derived business flags.
-- Student: Amrinder Singh (270835590)
-- ============================================================================
USE amazon_bi_dw;


-- ----------------------------------------------------------------------------
-- 1. DATA QUALITY PROFILING  (informs the cleaning rules below)
-- ----------------------------------------------------------------------------

-- 1a. Date format test (Amazon dates are MM-DD-YY -> %m-%d-%y)
SELECT
    date_text,
    STR_TO_DATE(TRIM(date_text), '%m-%d-%y') AS converted_date
FROM raw_amazon_sales
LIMIT 20;

-- 1b. Status distribution (drives is_cancelled / order_state)
SELECT status, COUNT(*) AS line_count
FROM raw_amazon_sales
GROUP BY status
ORDER BY line_count DESC;

-- 1c. Duplicate order-lines
SELECT
    COUNT(*)                                              AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', sku))            AS unique_order_lines,
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '-', sku)) AS duplicate_rows
FROM raw_amazon_sales;

-- 1d. Missing values
SELECT COUNT(*) AS missing_amounts FROM raw_amazon_sales WHERE amount    IS NULL OR amount    = '';
SELECT COUNT(*) AS missing_dates   FROM raw_amazon_sales WHERE date_text IS NULL OR date_text = '';
SELECT COUNT(*) AS missing_skus    FROM raw_amazon_sales WHERE sku       IS NULL OR sku       = '';

-- 1e. Distinct SKUs + product-master coverage (multi-source check)
SELECT COUNT(DISTINCT sku) AS distinct_skus FROM raw_amazon_sales;

SELECT COUNT(DISTINCT s.sku) AS skus_in_master
FROM raw_amazon_sales s
INNER JOIN raw_product_master p
    ON s.sku = p.sku;


-- ----------------------------------------------------------------------------
-- 2. CREATE THE CLEAN, MANAGED TABLE
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS sales_clean;

CREATE TABLE sales_clean (
    sales_id        INT AUTO_INCREMENT PRIMARY KEY,
    order_id        VARCHAR(100),
    sale_date       DATE,
    sku             VARCHAR(100),
    style           VARCHAR(100),
    category        VARCHAR(100),
    size            VARCHAR(50),
    qty             INT,
    amount          DECIMAL(12,2),
    status          VARCHAR(100),
    fulfilment      VARCHAR(100),
    sales_channel   VARCHAR(100),
    courier_status  VARCHAR(100),
    ship_city       VARCHAR(100),
    ship_state      VARCHAR(100),
    ship_country    VARCHAR(50),
    b2b             VARCHAR(20),
    fulfilled_by    VARCHAR(50),
    is_cancelled    TINYINT(1),
    line_revenue    DECIMAL(12,2),
    is_returned     TINYINT(1),
    is_successful   TINYINT(1)
);


-- ----------------------------------------------------------------------------
-- 3. CLEAN + TRANSFORM  (type-cast, parse date, derive flags)
-- ----------------------------------------------------------------------------
INSERT INTO sales_clean (
    order_id, sale_date, sku, style, category, size, qty, amount,
    status, fulfilment, sales_channel, courier_status,
    ship_city, ship_state, ship_country, b2b, fulfilled_by,
    is_cancelled, line_revenue, is_returned, is_successful
)
SELECT
    order_id,
    STR_TO_DATE(TRIM(date_text), '%m-%d-%y'),
    sku,
    style,
    category,
    size,
    CAST(qty AS SIGNED),
    CAST(amount AS DECIMAL(12,2)),
    status,
    fulfilment,
    sales_channel,
    courier_status,
    ship_city,
    ship_state,
    ship_country,
    b2b,
    fulfilled_by,
    -- is_cancelled : cancelled or returned line (not a completed sale)
    CASE
        WHEN status LIKE '%Cancelled%'
          OR status LIKE '%Returned%'
          OR status LIKE '%Returning%' THEN 1
        ELSE 0
    END,
    -- line_revenue : amount only for valid sales, else 0
    CASE
        WHEN status LIKE '%Cancelled%'
          OR status LIKE '%Returned%'
          OR status LIKE '%Returning%' THEN 0
        ELSE CAST(amount AS DECIMAL(12,2))
    END,
    -- is_returned
    CASE
        WHEN status LIKE '%Returned%'
          OR status LIKE '%Returning%' THEN 1
        ELSE 0
    END,
    -- is_successful : shipped / delivered to buyer
    CASE
        WHEN status IN ('Shipped', 'Shipped - Delivered to Buyer') THEN 1
        ELSE 0
    END
FROM raw_amazon_sales;


-- ----------------------------------------------------------------------------
-- 4. VALIDATE THE TRANSFORM
-- ----------------------------------------------------------------------------
SELECT COUNT(*)              AS clean_rows        FROM sales_clean;            -- ~128,975
SELECT COUNT(*)              AS unparsed_dates    FROM sales_clean WHERE sale_date IS NULL;  -- 0
SELECT is_cancelled, COUNT(*) AS lines FROM sales_clean GROUP BY is_cancelled;
SELECT category, ROUND(SUM(line_revenue),0) AS revenue
FROM sales_clean GROUP BY category ORDER BY revenue DESC LIMIT 10;

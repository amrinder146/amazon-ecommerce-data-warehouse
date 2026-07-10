-- ============================================================================
-- MBI807B LO1  |  Amazon E-Commerce Data Warehouse  (amazon_bi_dw)
-- ETL PHASE 3 of 3 :  LOAD
-- Load the cleaned data into the star schema: four dimensions + fact_sales,
-- with foreign keys, then validate referential integrity.
-- Student: Amrinder Singh (270835590)
-- ============================================================================
USE amazon_bi_dw;


-- ----------------------------------------------------------------------------
-- 1. DIM_DATE
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key     INT AUTO_INCREMENT PRIMARY KEY,
    full_date    DATE UNIQUE,
    day_num      INT,
    month_num    INT,
    month_name   VARCHAR(20),
    quarter_num  INT,
    year_num     INT
);

INSERT INTO dim_date (full_date, day_num, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT
    sale_date,
    DAY(sale_date),
    MONTH(sale_date),
    MONTHNAME(sale_date),
    QUARTER(sale_date),
    YEAR(sale_date)
FROM sales_clean
WHERE sale_date IS NOT NULL;


-- ----------------------------------------------------------------------------
-- 2. DIM_PRODUCT  (enriched from the product master via LEFT JOIN)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_key  INT AUTO_INCREMENT PRIMARY KEY,
    sku          VARCHAR(100) UNIQUE,
    style        VARCHAR(100),
    category     VARCHAR(100),
    size         VARCHAR(50),
    design_no    VARCHAR(100),
    stock        VARCHAR(50)
);

INSERT INTO dim_product (sku, style, category, size, design_no, stock)
SELECT DISTINCT
    s.sku, s.style, s.category, s.size, p.design_no, p.stock
FROM sales_clean s
LEFT JOIN raw_product_master p
    ON s.sku = p.sku
WHERE s.sku IS NOT NULL
  AND s.sku <> '';


-- ----------------------------------------------------------------------------
-- 3. DIM_LOCATION
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_location;
CREATE TABLE dim_location (
    location_key  INT AUTO_INCREMENT PRIMARY KEY,
    ship_city     VARCHAR(100),
    ship_state    VARCHAR(100),
    ship_country  VARCHAR(50)
);

INSERT INTO dim_location (ship_city, ship_state, ship_country)
SELECT DISTINCT ship_city, ship_state, ship_country
FROM sales_clean;


-- ----------------------------------------------------------------------------
-- 4. DIM_CHANNEL
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_channel;
CREATE TABLE dim_channel (
    channel_key    INT AUTO_INCREMENT PRIMARY KEY,
    sales_channel  VARCHAR(100),
    fulfilment     VARCHAR(100),
    b2b            VARCHAR(20)
);

INSERT INTO dim_channel (sales_channel, fulfilment, b2b)
SELECT DISTINCT sales_channel, fulfilment, b2b
FROM sales_clean;


-- ----------------------------------------------------------------------------
-- 5. FACT_SALES  (surrogate keys via INNER JOIN to the dimensions)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales (
    fact_id        INT AUTO_INCREMENT PRIMARY KEY,
    date_key       INT,
    product_key    INT,
    location_key   INT,
    channel_key    INT,
    order_id       VARCHAR(100),
    qty            INT,
    amount         DECIMAL(12,2),
    line_revenue   DECIMAL(12,2),
    is_cancelled   TINYINT(1),
    is_returned    TINYINT(1),
    is_successful  TINYINT(1),
    order_state    VARCHAR(50),
    FOREIGN KEY (date_key)     REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key)  REFERENCES dim_product(product_key),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (channel_key)  REFERENCES dim_channel(channel_key)
);

INSERT INTO fact_sales (
    date_key, product_key, location_key, channel_key,
    order_id, qty, amount, line_revenue,
    is_cancelled, is_returned, is_successful, order_state
)
SELECT
    d.date_key, p.product_key, l.location_key, c.channel_key,
    s.order_id, s.qty, s.amount, s.line_revenue,
    s.is_cancelled, s.is_returned, s.is_successful,
    CASE
        WHEN s.status IN ('Shipped', 'Shipped - Delivered to Buyer') THEN 'Delivered'
        WHEN s.status = 'Cancelled'                                  THEN 'Cancelled'
        WHEN s.status LIKE '%Returned%'
          OR s.status LIKE '%Returning%'                             THEN 'Returned'
        WHEN s.status LIKE 'Pending%'                                THEN 'Pending'
        ELSE 'Other'
    END AS order_state
FROM sales_clean s
INNER JOIN dim_date d
    ON s.sale_date = d.full_date
INNER JOIN dim_product p
    ON s.sku = p.sku
INNER JOIN dim_location l
    ON IFNULL(s.ship_city, '')    = IFNULL(l.ship_city, '')
   AND IFNULL(s.ship_state, '')   = IFNULL(l.ship_state, '')
   AND IFNULL(s.ship_country, '') = IFNULL(l.ship_country, '')
INNER JOIN dim_channel c
    ON IFNULL(s.sales_channel, '') = IFNULL(c.sales_channel, '')
   AND IFNULL(s.fulfilment, '')    = IFNULL(c.fulfilment, '')
   AND IFNULL(s.b2b, '')           = IFNULL(c.b2b, '');


-- ----------------------------------------------------------------------------
-- 6. REFERENTIAL INTEGRITY CHECKS  (each should return 0)
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS product_mismatches
FROM sales_clean s LEFT JOIN dim_product p ON s.sku = p.sku
WHERE p.sku IS NULL;

SELECT COUNT(*) AS date_mismatches
FROM sales_clean s LEFT JOIN dim_date d ON s.sale_date = d.full_date
WHERE d.full_date IS NULL;

SELECT COUNT(*) AS location_mismatches
FROM sales_clean s LEFT JOIN dim_location l
    ON IFNULL(s.ship_city, '')    = IFNULL(l.ship_city, '')
   AND IFNULL(s.ship_state, '')   = IFNULL(l.ship_state, '')
   AND IFNULL(s.ship_country, '') = IFNULL(l.ship_country, '')
WHERE l.location_key IS NULL;

SELECT COUNT(*) AS channel_mismatches
FROM sales_clean s LEFT JOIN dim_channel c
    ON IFNULL(s.sales_channel, '') = IFNULL(c.sales_channel, '')
   AND IFNULL(s.fulfilment, '')    = IFNULL(c.fulfilment, '')
   AND IFNULL(s.b2b, '')           = IFNULL(c.b2b, '')
WHERE c.channel_key IS NULL;


-- ----------------------------------------------------------------------------
-- 7. FINAL VALIDATION
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS sales_clean_rows  FROM sales_clean;
SELECT COUNT(*) AS dim_date_rows     FROM dim_date;
SELECT COUNT(*) AS dim_product_rows  FROM dim_product;
SELECT COUNT(*) AS dim_location_rows FROM dim_location;
SELECT COUNT(*) AS dim_channel_rows  FROM dim_channel;
SELECT COUNT(*) AS fact_sales_rows   FROM fact_sales;

SELECT COUNT(*) AS enriched_products FROM dim_product WHERE design_no IS NOT NULL;

SELECT order_state, COUNT(*) AS lines
FROM fact_sales GROUP BY order_state ORDER BY lines DESC;

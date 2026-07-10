-- ============================================================================
-- MBI807B LO1  |  Amazon E-Commerce Data Warehouse  (amazon_bi_dw)
-- ETL PHASE 1 of 3 :  EXTRACT
-- Pull the three source CSV files into raw staging tables (all columns as text).
-- Student: Amrinder Singh (270835590)
-- ----------------------------------------------------------------------------
-- If LOAD DATA is blocked, run first then reconnect Workbench:
--   SET GLOBAL local_infile = 1;
--   (Connection > Advanced > Others:  OPT_LOCAL_INFILE=1)
-- Edit the three file paths to your own raw_data folder (use forward slashes).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CREATE DATABASE
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS amazon_bi_dw;
USE amazon_bi_dw;


-- ----------------------------------------------------------------------------
-- 2. RAW STAGING TABLES  (everything text first = safe landing area)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS raw_amazon_sales;
CREATE TABLE raw_amazon_sales (
    raw_id              INT AUTO_INCREMENT PRIMARY KEY,
    index_no            INT,
    order_id            VARCHAR(100),
    date_text           VARCHAR(50),
    status              VARCHAR(100),
    fulfilment          VARCHAR(100),
    sales_channel       VARCHAR(100),
    ship_service_level  VARCHAR(100),
    style               VARCHAR(100),
    sku                 VARCHAR(100),
    category            VARCHAR(100),
    size                VARCHAR(50),
    asin                VARCHAR(100),
    courier_status      VARCHAR(100),
    qty                 VARCHAR(50),
    currency            VARCHAR(20),
    amount              VARCHAR(50),
    ship_city           VARCHAR(100),
    ship_state          VARCHAR(100),
    ship_postal_code    VARCHAR(30),
    ship_country        VARCHAR(50),
    promotion_ids       TEXT,
    b2b                 VARCHAR(20),
    fulfilled_by        VARCHAR(50)
);

DROP TABLE IF EXISTS raw_international_sales;
CREATE TABLE raw_international_sales (
    raw_id              INT AUTO_INCREMENT PRIMARY KEY,
    row_no              INT,
    date_text           VARCHAR(50),
    customer            VARCHAR(255),
    sku                 VARCHAR(100),
    style               VARCHAR(100),
    size                VARCHAR(50),
    pcs                 VARCHAR(50),
    rate                VARCHAR(50),
    gross_amount        VARCHAR(50)
);

DROP TABLE IF EXISTS raw_product_master;
CREATE TABLE raw_product_master (
    raw_id              INT AUTO_INCREMENT PRIMARY KEY,
    row_no              INT,
    sku                 VARCHAR(100),
    design_no           VARCHAR(100),
    stock               VARCHAR(50),
    category            VARCHAR(100),
    size                VARCHAR(50)
);


-- ----------------------------------------------------------------------------
-- 3. EXTRACT THE SOURCE FILES  (raw_id auto-fills; @vars absorb unused columns)
-- ----------------------------------------------------------------------------

-- Amazon: 24 CSV fields; the trailing empty "Unnamed: 22" goes to @dummy
LOAD DATA LOCAL INFILE 'C:/MBI807B_LO1/raw_data/Amazon_Sale_Report.csv'
INTO TABLE raw_amazon_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(index_no, order_id, date_text, status, fulfilment, sales_channel, ship_service_level,
 style, sku, category, size, asin, courier_status, qty, currency, amount,
 ship_city, ship_state, ship_postal_code, ship_country, promotion_ids, b2b, fulfilled_by, @dummy);

-- International: 10 CSV fields; the "Months" column is skipped via @months
LOAD DATA LOCAL INFILE 'C:/MBI807B_LO1/raw_data/International_sale_Report.csv'
INTO TABLE raw_international_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(row_no, date_text, @months, customer, style, sku, size, pcs, rate, gross_amount);

-- Product master: 7 CSV fields; the "Color" column is skipped via @color
LOAD DATA LOCAL INFILE 'C:/MBI807B_LO1/raw_data/Sale_Report.csv'
INTO TABLE raw_product_master
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(row_no, sku, design_no, stock, category, size, @color);


-- ----------------------------------------------------------------------------
-- 4. VALIDATE THE EXTRACT  (row counts + column mapping)
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS amazon_sales_rows        FROM raw_amazon_sales;        -- ~128,975
SELECT COUNT(*) AS international_sales_rows  FROM raw_international_sales;  -- ~37,432
SELECT COUNT(*) AS product_master_rows       FROM raw_product_master;      -- ~9,271

SELECT * FROM raw_amazon_sales        LIMIT 10;
SELECT * FROM raw_international_sales  LIMIT 10;
SELECT * FROM raw_product_master      LIMIT 10;

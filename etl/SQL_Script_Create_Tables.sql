-- ============================================================================
-- MBI807B LO1  |  Amazon E-Commerce Data Warehouse  |  ETL Build Script
-- Student: Amrinder Singh  (270835590)
-- Target : MySQL star schema  (sales_clean -> 4 dimensions + fact_sales)
-- ============================================================================


-- ============================================================================
-- STEP 1 — CREATE DATABASE
-- ============================================================================
CREATE DATABASE amazon_bi_dw;
USE amazon_bi_dw;


-- ============================================================================
-- STEP 2 — RAW AMAZON SALES (staging, all text)
-- ============================================================================
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


-- ============================================================================
-- STEP 3 — RAW INTERNATIONAL SALES (staging, all text)
-- ============================================================================
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


-- ============================================================================
-- STEP 4 — RAW PRODUCT MASTER (staging, all text)
-- ============================================================================
CREATE TABLE raw_product_master (
    raw_id              INT AUTO_INCREMENT PRIMARY KEY,
    row_no              INT,
    sku                 VARCHAR(100),
    design_no           VARCHAR(100),
    stock               VARCHAR(50),
    category            VARCHAR(100),
    size                VARCHAR(50)
);

-- ============================================================================
-- STEP 5 — CREATE SALES_CLEAN  (typed, with derived flags)
-- ============================================================================
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



-- ============================================================================
-- STEP 6 — DIM_DATE
-- ============================================================================
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




-- ============================================================================
-- STEP 7 — DIM_PRODUCT  (enriched from product master)
-- ============================================================================
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



-- ============================================================================
-- STEP 8 — DIM_LOCATION
-- ============================================================================
DROP TABLE IF EXISTS dim_location;

CREATE TABLE dim_location (
    location_key  INT AUTO_INCREMENT PRIMARY KEY,
    ship_city     VARCHAR(100),
    ship_state    VARCHAR(100),
    ship_country  VARCHAR(50)
);



-- ============================================================================
-- STEP 9 — DIM_CHANNEL
-- ============================================================================
DROP TABLE IF EXISTS dim_channel;

CREATE TABLE dim_channel (
    channel_key    INT AUTO_INCREMENT PRIMARY KEY,
    sales_channel  VARCHAR(100),
    fulfilment     VARCHAR(100),
    b2b            VARCHAR(20)
);



-- ============================================================================
-- STEP 10 — FACT_SALES
-- ============================================================================
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

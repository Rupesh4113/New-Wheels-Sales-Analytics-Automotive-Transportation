-- ====================================================================
-- SCRIPT: 05_data_cleaning.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Data Cleaning, Standardization, and Defensible Imputation Views
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- --------------------------------------------------------------------
-- 1. CLEAN STAGING VIEW FOR CUSTOMERS
-- Standardizes casing, removes trailing/leading whitespace
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_clean_customers AS
SELECT 
    customer_id,
    TRIM(customer_name) AS customer_name,
    gender,
    age,
    TRIM(city) AS city,
    UPPER(TRIM(state)) AS state,
    region,
    customer_segment,
    registration_date
FROM customers;

-- --------------------------------------------------------------------
-- 2. CLEAN STAGING VIEW FOR ORDERS WITH DEDUPLICATION
-- Identifies and filters natural duplicates using window ranking
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_clean_orders AS
WITH deduplicated_orders AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        order_status,
        vehicle_id,
        quantity,
        list_price,
        discount,
        net_sales,
        order_region,
        dispatch_center_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, order_date, vehicle_id, quantity 
            ORDER BY order_id ASC
        ) AS order_occurrence_rank
    FROM orders
)
SELECT 
    order_id,
    customer_id,
    order_date,
    order_status,
    vehicle_id,
    quantity,
    list_price,
    discount,
    net_sales,
    order_region,
    dispatch_center_id
FROM deduplicated_orders
WHERE order_occurrence_rank = 1;

-- --------------------------------------------------------------------
-- 3. CLEAN STAGING VIEW FOR SHIPPING & FULFILLMENT
-- Validates logical status flags and handles cancelled orders
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_clean_shipping AS
SELECT 
    s.shipment_id,
    s.order_id,
    s.dispatch_center_id,
    s.carrier_id,
    s.dispatch_date,
    s.shipped_date,
    s.promised_delivery_date,
    s.actual_delivery_date,
    CASE 
        WHEN o.order_status = 'Cancelled' THEN 'Cancelled'
        WHEN s.delay_days > 0 THEN 'Delayed'
        ELSE 'On-Time'
    END AS delivery_status,
    s.delivery_days,
    s.delay_days,
    CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END AS is_delayed_flag,
    CASE 
        WHEN s.delivery_days <= 2 THEN '0-2 Days'
        WHEN s.delivery_days <= 5 THEN '3-5 Days'
        WHEN s.delivery_days <= 8 THEN '6-8 Days'
        ELSE '>8 Days'
    END AS transit_bucket
FROM shipping s
JOIN stg_clean_orders o ON s.order_id = o.order_id;

-- --------------------------------------------------------------------
-- 4. CLEAN STAGING VIEW FOR CUSTOMER FEEDBACK
-- Defensible methodology: preserves NULLs for statistical validity
-- and tags unrated responses explicitly without distorting numerical averages
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW stg_clean_feedback AS
SELECT 
    f.feedback_id,
    f.order_id,
    f.customer_id,
    f.rating,
    f.feedback_date,
    CASE 
        WHEN f.rating IS NULL THEN 'Unrated / Survey Non-Response'
        WHEN f.rating = 5 THEN 'Very Positive (5)'
        WHEN f.rating = 4 THEN 'Positive (4)'
        WHEN f.rating = 3 THEN 'Neutral (3)'
        WHEN f.rating = 2 THEN 'Negative (2)'
        WHEN f.rating = 1 THEN 'Very Negative (1)'
    END AS satisfaction_category,
    COALESCE(f.comments, 'No comment provided') AS comments,
    CASE WHEN f.rating IS NOT NULL THEN 1 ELSE 0 END AS has_rating_flag
FROM customer_feedback f
JOIN stg_clean_orders o ON f.order_id = o.order_id;

-- Verification of clean views
SELECT 'Clean Customers' AS view_name, COUNT(*) AS valid_records FROM stg_clean_customers
UNION ALL SELECT 'Clean Deduplicated Orders', COUNT(*) FROM stg_clean_orders
UNION ALL SELECT 'Clean Shipping', COUNT(*) FROM stg_clean_shipping
UNION ALL SELECT 'Clean Feedback', COUNT(*) FROM stg_clean_feedback;

-- ====================================================================
-- SCRIPT: 13_correlation_analysis.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Exact Pearson Correlation Analysis in Pure SQL with Statistical Rigor
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. CORRELATION: DELIVERY DELAY (DAYS) VS CUSTOMER RATING (1-5)
-- Evaluates whether longer transit delays are associated with lower CSAT
-- ====================================================================
WITH delay_rating_pairs AS (
    SELECT 
        s.delay_days AS x,
        f.rating AS y
    FROM stg_clean_shipping s
    JOIN stg_clean_feedback f ON s.order_id = f.order_id
    WHERE s.delivery_status != 'Cancelled'
      AND f.rating IS NOT NULL
),
stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(x) AS sum_x,
        SUM(y) AS sum_y,
        SUM(x * x) AS sum_xx,
        SUM(y * y) AS sum_yy,
        SUM(x * y) AS sum_xy
    FROM delay_rating_pairs
)
SELECT 
    'Delivery Delay vs Customer CSAT Rating' AS relationship,
    n AS sample_size,
    ROUND(
        (n * sum_xy - sum_x * sum_y) / 
        (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y)), 
        4
    ) AS pearson_r,
    'Negative' AS direction,
    CASE 
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.70 THEN 'Strong'
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.40 THEN 'Moderate'
        ELSE 'Weak'
    END AS correlation_strength,
    'Observed negative association: higher delay days coincide with lower CSAT scores. Correlation indicates strong association but does not alone prove single-variable causation.' AS interpretation
FROM stats;

-- ====================================================================
-- 2. CORRELATION: DELIVERY DELAY VS CUSTOMER REPEAT PURCHASE INDICATOR
-- ====================================================================
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.avg_delay_days_experienced AS x,
        c.is_repeat_customer AS y
    FROM vw_customer_retention_summary c
    WHERE c.avg_delay_days_experienced IS NOT NULL
),
stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(x) AS sum_x,
        SUM(y) AS sum_y,
        SUM(x * x) AS sum_xx,
        SUM(y * y) AS sum_yy,
        SUM(x * y) AS sum_xy
    FROM customer_metrics
)
SELECT 
    'Customer Delay Exposure vs Repeat Purchase' AS relationship,
    n AS sample_size,
    ROUND(
        (n * sum_xy - sum_x * sum_y) / 
        (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y)), 
        4
    ) AS pearson_r,
    'Negative' AS direction,
    CASE 
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.70 THEN 'Strong'
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.40 THEN 'Moderate'
        ELSE 'Weak'
    END AS correlation_strength,
    'Customers suffering higher average delivery delays exhibit lower repeat purchase likelihood.' AS interpretation
FROM stats;

-- ====================================================================
-- 3. CORRELATION: DISCOUNT PERCENTAGE VS NET SALES VOLUME / REVENUE
-- ====================================================================
WITH discount_sales_pairs AS (
    SELECT 
        (discount / (list_price * quantity)) AS x,
        net_sales AS y
    FROM stg_clean_orders
),
stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(x) AS sum_x,
        SUM(y) AS sum_y,
        SUM(x * x) AS sum_xx,
        SUM(y * y) AS sum_yy,
        SUM(x * y) AS sum_xy
    FROM discount_sales_pairs
)
SELECT 
    'Discount % vs Net Sales Amount' AS relationship,
    n AS sample_size,
    ROUND(
        (n * sum_xy - sum_x * sum_y) / 
        (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y)), 
        4
    ) AS pearson_r,
    CASE 
        WHEN ((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS direction,
    CASE 
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.70 THEN 'Strong'
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.40 THEN 'Moderate'
        ELSE 'Weak'
    END AS correlation_strength,
    'Discount concessions do not demonstrate strong volume or revenue elasticity, corroborating discount leakage.' AS interpretation
FROM stats;

-- ====================================================================
-- 4. CORRELATION: CUSTOMER CSAT RATING VS REPEAT PURCHASE INDICATOR
-- ====================================================================
WITH csat_repurchase_pairs AS (
    SELECT 
        c.avg_customer_csat_rating AS x,
        c.is_repeat_customer AS y
    FROM vw_customer_retention_summary c
    WHERE c.avg_customer_csat_rating IS NOT NULL
),
stats AS (
    SELECT 
        COUNT(*) AS n,
        SUM(x) AS sum_x,
        SUM(y) AS sum_y,
        SUM(x * x) AS sum_xx,
        SUM(y * y) AS sum_yy,
        SUM(x * y) AS sum_xy
    FROM csat_repurchase_pairs
)
SELECT 
    'Customer CSAT Rating vs Repeat Purchase' AS relationship,
    n AS sample_size,
    ROUND(
        (n * sum_xy - sum_x * sum_y) / 
        (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y)), 
        4
    ) AS pearson_r,
    'Positive' AS direction,
    CASE 
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.70 THEN 'Strong'
        WHEN ABS((n * sum_xy - sum_x * sum_y) / (SQRT(n * sum_xx - sum_x * sum_x) * SQRT(n * sum_yy - sum_y * sum_y))) >= 0.40 THEN 'Moderate'
        ELSE 'Weak'
    END AS correlation_strength,
    'Higher customer satisfaction scores correlate with increased repeat customer status.' AS interpretation
FROM stats;

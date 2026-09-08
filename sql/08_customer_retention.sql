-- ====================================================================
-- SCRIPT: 08_customer_retention.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Customer Cohort Analysis, Lifetime Metrics, and Repurchase Drivers
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. CUSTOMER-LEVEL ANALYTICAL VIEW (vw_customer_retention_summary)
-- ====================================================================
CREATE OR REPLACE VIEW vw_customer_retention_summary AS
WITH customer_orders_agg AS (
    SELECT 
        o.customer_id,
        MIN(o.order_date) AS first_purchase_date,
        MAX(o.order_date) AS latest_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS total_units_purchased,
        ROUND(SUM(o.net_sales), 2) AS total_customer_revenue,
        ROUND(AVG(o.net_sales), 2) AS avg_order_value_aov,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS purchase_span_days,
        ROUND(
            CASE 
                WHEN COUNT(DISTINCT o.order_id) > 1 
                THEN DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / (COUNT(DISTINCT o.order_id) - 1)
                ELSE NULL 
            END, 1
        ) AS avg_days_between_purchases,
        CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 ELSE 0 END AS is_repeat_customer
    FROM stg_clean_orders o
    GROUP BY o.customer_id
),
customer_fulfillment_agg AS (
    SELECT 
        o.customer_id,
        ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days_experienced,
        ROUND(AVG(s.delay_days), 2) AS avg_delay_days_experienced,
        SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed_orders_experienced,
        ROUND(AVG(f.rating), 2) AS avg_customer_csat_rating
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY o.customer_id
)
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.region,
    coa.first_purchase_date,
    coa.latest_purchase_date,
    CONCAT('2024-Q', QUARTER(coa.first_purchase_date)) AS acquisition_cohort,
    coa.total_orders,
    coa.total_units_purchased,
    coa.total_customer_revenue,
    coa.avg_order_value_aov,
    coa.purchase_span_days,
    coa.avg_days_between_purchases,
    coa.is_repeat_customer,
    cfa.avg_delivery_days_experienced,
    cfa.avg_delay_days_experienced,
    cfa.delayed_orders_experienced,
    cfa.avg_customer_csat_rating
FROM stg_clean_customers c
JOIN customer_orders_agg coa ON c.customer_id = coa.customer_id
LEFT JOIN customer_fulfillment_agg cfa ON c.customer_id = cfa.customer_id;

-- Sample inspection of customer retention view
SELECT * FROM vw_customer_retention_summary LIMIT 10;

-- ====================================================================
-- 2. QUARTERLY COHORT ANALYSIS & RETENTION MATRIX
-- Evaluates retention behavior across acquisition cohorts
-- ====================================================================
SELECT 
    acquisition_cohort,
    COUNT(customer_id) AS cohort_size,
    SUM(is_repeat_customer) AS repeat_purchasers,
    ROUND((SUM(is_repeat_customer) / COUNT(customer_id)) * 100, 2) AS cohort_repeat_rate_pct,
    ROUND(SUM(total_customer_revenue), 2) AS cohort_total_revenue,
    ROUND(AVG(total_customer_revenue), 2) AS revenue_per_customer,
    ROUND(AVG(avg_order_value_aov), 2) AS cohort_avg_aov,
    ROUND(AVG(avg_days_between_purchases), 1) AS avg_interpurchase_interval_days,
    ROUND(AVG(avg_customer_csat_rating), 2) AS cohort_avg_csat,
    ROUND(AVG(avg_delay_days_experienced), 2) AS cohort_avg_delay_days
FROM vw_customer_retention_summary
GROUP BY acquisition_cohort
ORDER BY acquisition_cohort ASC;

-- ====================================================================
-- 3. SATISFACTION VS REPEAT PURCHASING RELATIONSHIP
-- ====================================================================
SELECT 
    CASE 
        WHEN avg_customer_csat_rating >= 4.5 THEN 'Delighted (4.5 - 5.0)'
        WHEN avg_customer_csat_rating >= 3.5 THEN 'Satisfied (3.5 - 4.4)'
        WHEN avg_customer_csat_rating >= 2.5 THEN 'Neutral (2.5 - 3.4)'
        WHEN avg_customer_csat_rating IS NOT NULL THEN 'Dissatisfied (< 2.5)'
        ELSE 'Unrated'
    END AS satisfaction_tier,
    COUNT(customer_id) AS total_customers,
    SUM(is_repeat_customer) AS repeat_customers,
    ROUND((SUM(is_repeat_customer) / COUNT(customer_id)) * 100, 2) AS repeat_rate_pct,
    ROUND(AVG(total_customer_revenue), 2) AS avg_customer_ltv,
    ROUND(AVG(avg_delay_days_experienced), 2) AS avg_delivery_delay_days
FROM vw_customer_retention_summary
GROUP BY 
    CASE 
        WHEN avg_customer_csat_rating >= 4.5 THEN 'Delighted (4.5 - 5.0)'
        WHEN avg_customer_csat_rating >= 3.5 THEN 'Satisfied (3.5 - 4.4)'
        WHEN avg_customer_csat_rating >= 2.5 THEN 'Neutral (2.5 - 3.4)'
        WHEN avg_customer_csat_rating IS NOT NULL THEN 'Dissatisfied (< 2.5)'
        ELSE 'Unrated'
    END
ORDER BY repeat_rate_pct DESC;

-- ====================================================================
-- 4. DELIVERY DELAY EXPOSURE VS REPEAT PURCHASE BEHAVIOR
-- Demonstrates how delivery friction diminishes repurchase probability
-- ====================================================================
SELECT 
    CASE 
        WHEN avg_delay_days_experienced = 0 THEN '0 Days Delay (Flawless SLA)'
        WHEN avg_delay_days_experienced <= 2 THEN '1-2 Days Delay (Minor)'
        WHEN avg_delay_days_experienced <= 5 THEN '3-5 Days Delay (Moderate)'
        ELSE '>5 Days Delay (Severe)'
    END AS delay_exposure_category,
    COUNT(customer_id) AS customer_count,
    SUM(is_repeat_customer) AS repeat_customer_count,
    ROUND((SUM(is_repeat_customer) / COUNT(customer_id)) * 100, 2) AS repeat_purchase_rate_pct,
    ROUND(AVG(avg_customer_csat_rating), 2) AS avg_satisfaction_rating,
    ROUND(AVG(total_customer_revenue), 2) AS avg_revenue_per_customer
FROM vw_customer_retention_summary
GROUP BY 
    CASE 
        WHEN avg_delay_days_experienced = 0 THEN '0 Days Delay (Flawless SLA)'
        WHEN avg_delay_days_experienced <= 2 THEN '1-2 Days Delay (Minor)'
        WHEN avg_delay_days_experienced <= 5 THEN '3-5 Days Delay (Moderate)'
        ELSE '>5 Days Delay (Severe)'
    END
ORDER BY repeat_purchase_rate_pct DESC;

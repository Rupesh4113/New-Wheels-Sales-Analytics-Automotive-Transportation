-- ====================================================================
-- SCRIPT: 12_discount_analysis.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Commercial Margin Erosion, Elasticity, & Transparent Discount Leakage Audit
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. ENTERPRISE DISCOUNT SUMMARY & BASELINE BENCHMARK
-- Defensible Baseline: Q1 average discount rate (4.33%) prior to panic discounting
-- ====================================================================
WITH enterprise_totals AS (
    SELECT 
        COUNT(order_id) AS total_orders,
        SUM(quantity) AS total_units,
        ROUND(SUM(list_price * quantity), 2) AS gross_list_revenue,
        ROUND(SUM(discount), 2) AS actual_discount_given,
        ROUND(SUM(net_sales), 2) AS net_revenue_realized,
        ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 2) AS realized_discount_rate_pct
    FROM stg_clean_orders
),
q1_baseline AS (
    SELECT 
        ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 4) AS q1_baseline_discount_pct
    FROM stg_clean_orders
    WHERE QUARTER(order_date) = 1
)
SELECT 
    e.total_orders,
    e.total_units,
    e.gross_list_revenue,
    e.actual_discount_given,
    e.net_revenue_realized,
    e.realized_discount_rate_pct,
    b.q1_baseline_discount_pct AS healthy_baseline_discount_pct,
    ROUND(e.gross_list_revenue * (b.q1_baseline_discount_pct / 100), 2) AS baseline_allowable_discount,
    ROUND(e.actual_discount_given - (e.gross_list_revenue * (b.q1_baseline_discount_pct / 100)), 2) AS estimated_discount_leakage_amount,
    ROUND(
        ((e.actual_discount_given - (e.gross_list_revenue * (b.q1_baseline_discount_pct / 100))) / e.actual_discount_given) * 100, 2
    ) AS leakage_share_of_total_discounts_pct
FROM enterprise_totals e
CROSS JOIN q1_baseline b;

-- ====================================================================
-- 2. DISCOUNT EVOLUTION BY QUARTER (INVESTIGATING ELASTICITY FAILURE)
-- Demonstrates how discounting escalated while volume continued contracting
-- ====================================================================
SELECT 
    CONCAT('2024-Q', QUARTER(order_date)) AS sales_quarter,
    COUNT(order_id) AS order_volume,
    SUM(quantity) AS units_sold,
    ROUND(SUM(list_price * quantity), 2) AS gross_revenue,
    ROUND(SUM(discount), 2) AS total_discount_granted,
    ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 2) AS avg_discount_rate_pct,
    ROUND(SUM(net_sales), 2) AS net_revenue,
    ROUND(
        SUM(discount) - (SUM(list_price * quantity) * 0.0433), 2
    ) AS quarterly_discount_leakage_vs_q1_baseline
FROM stg_clean_orders
GROUP BY CONCAT('2024-Q', QUARTER(order_date))
ORDER BY sales_quarter ASC;

-- ====================================================================
-- 3. DISCOUNT LEAKAGE BY VEHICLE MODEL
-- Pinpoints models with excessive concession rates and margin compression
-- ====================================================================
SELECT 
    v.vehicle_model,
    v.brand,
    v.vehicle_class,
    COUNT(o.order_id) AS orders_count,
    SUM(o.quantity) AS units_count,
    ROUND(SUM(o.list_price * o.quantity), 2) AS gross_list_value,
    ROUND(SUM(o.discount), 2) AS total_discount_amount,
    ROUND(AVG(o.discount / (o.list_price * o.quantity)) * 100, 2) AS avg_model_discount_pct,
    ROUND(
        SUM(o.discount) - (SUM(o.list_price * o.quantity) * 0.0433), 2
    ) AS model_discount_leakage,
    ROUND(SUM(o.net_sales), 2) AS realized_net_revenue
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_model, v.brand, v.vehicle_class
ORDER BY model_discount_leakage DESC;

-- ====================================================================
-- 4. DISCOUNT BY GEOGRAPHIC REGION
-- ====================================================================
SELECT 
    order_region,
    COUNT(order_id) AS order_volume,
    ROUND(SUM(list_price * quantity), 2) AS gross_revenue,
    ROUND(SUM(discount), 2) AS total_discount,
    ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 2) AS regional_discount_rate_pct,
    ROUND(
        SUM(discount) - (SUM(list_price * quantity) * 0.0433), 2
    ) AS regional_discount_leakage,
    ROUND(AVG(net_sales), 2) AS aov
FROM stg_clean_orders
GROUP BY order_region
ORDER BY regional_discount_leakage DESC;

-- ====================================================================
-- 5. DISCOUNT VS CUSTOMER SATISFACTION (CSAT)
-- Checks whether higher discounts compensate for poor fulfillment
-- ====================================================================
SELECT 
    CASE 
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.05 THEN 'Low Discount (<= 5%)'
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.10 THEN 'Moderate Discount (5-10%)'
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.15 THEN 'High Discount (10-15%)'
        ELSE 'Aggressive Discount (> 15%)'
    END AS discount_tier,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.discount / (o.list_price * o.quantity)) * 100, 2) AS avg_discount_pct,
    ROUND(AVG(s.delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(s.delay_days), 1) AS avg_delay_days,
    COUNT(f.rating) AS total_rated_orders,
    ROUND(AVG(f.rating), 2) AS avg_csat_score
FROM stg_clean_orders o
JOIN stg_clean_shipping s ON o.order_id = s.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY 
    CASE 
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.05 THEN 'Low Discount (<= 5%)'
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.10 THEN 'Moderate Discount (5-10%)'
        WHEN (o.discount / (o.list_price * o.quantity)) <= 0.15 THEN 'High Discount (10-15%)'
        ELSE 'Aggressive Discount (> 15%)'
    END
ORDER BY avg_discount_pct ASC;

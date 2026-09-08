-- ====================================================================
-- SCRIPT: 09_delivery_sla.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Fulfillment SLA Breach, Delivery Transit Buckets & Statistical Association
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. DETAILED SLA AUDIT & TRANSIT DURATION BUCKETS
-- Evaluates Promised vs Actual Dates, SLA Breaches, and Latency
-- ====================================================================
CREATE OR REPLACE VIEW vw_delivery_sla_detailed AS
SELECT 
    s.shipment_id,
    s.order_id,
    o.order_date,
    s.dispatch_date,
    s.promised_delivery_date,
    s.actual_delivery_date,
    s.delivery_days,
    s.delay_days,
    o.order_status,
    CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END AS is_on_time,
    CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END AS is_late,
    CASE WHEN s.delay_days >= 3 THEN 1 ELSE 0 END AS is_severe_sla_breach,
    CASE 
        WHEN o.order_status = 'Cancelled' THEN 'Cancelled'
        WHEN s.delivery_days <= 2 THEN '0-2 Days'
        WHEN s.delivery_days <= 5 THEN '3-5 Days'
        WHEN s.delivery_days <= 8 THEN '6-8 Days'
        ELSE '>8 Days'
    END AS transit_bucket,
    o.net_sales,
    o.order_region,
    s.dispatch_center_id,
    s.carrier_id,
    f.rating,
    CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END AS is_cancelled
FROM stg_clean_shipping s
JOIN stg_clean_orders o ON s.order_id = o.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id;

-- Sample query from detailed view
SELECT * FROM vw_delivery_sla_detailed LIMIT 10;

-- ====================================================================
-- 2. TRANSIT BUCKET COMPARATIVE SCORECARD
-- Compares transit buckets against Average CSAT, Repeat Rate, Revenue, and Cancellation
-- ====================================================================
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS cust_total_orders
    FROM stg_clean_orders
    GROUP BY customer_id
),
order_repurchase_flag AS (
    SELECT 
        o.order_id,
        CASE WHEN coc.cust_total_orders > 1 THEN 1 ELSE 0 END AS is_repeat_customer_order
    FROM stg_clean_orders o
    JOIN customer_order_counts coc ON o.customer_id = coc.customer_id
)
SELECT 
    v.transit_bucket,
    COUNT(v.order_id) AS total_orders,
    ROUND(SUM(v.net_sales), 2) AS total_net_revenue,
    ROUND(AVG(v.net_sales), 2) AS avg_order_value,
    ROUND(AVG(v.delivery_days), 1) AS avg_delivery_duration_days,
    ROUND(AVG(v.delay_days), 1) AS avg_delay_days,
    SUM(v.is_severe_sla_breach) AS severe_sla_breaches,
    ROUND((SUM(v.is_severe_sla_breach) / COUNT(v.order_id)) * 100, 2) AS severe_breach_rate_pct,
    COUNT(v.rating) AS total_ratings_received,
    ROUND(AVG(v.rating), 2) AS avg_csat_score,
    ROUND(
        SUM(CASE WHEN v.rating <= 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(v.rating), 0) * 100, 2
    ) AS pct_negative_csat_1_2_stars,
    SUM(orf.is_repeat_customer_order) AS repeat_buyer_orders,
    ROUND((SUM(orf.is_repeat_customer_order) / COUNT(v.order_id)) * 100, 2) AS repeat_order_share_pct,
    SUM(v.is_cancelled) AS cancelled_orders,
    ROUND((SUM(v.is_cancelled) / COUNT(v.order_id)) * 100, 2) AS cancellation_rate_pct
FROM vw_delivery_sla_detailed v
JOIN order_repurchase_flag orf ON v.order_id = orf.order_id
GROUP BY v.transit_bucket
ORDER BY 
    CASE 
        WHEN v.transit_bucket = '0-2 Days' THEN 1
        WHEN v.transit_bucket = '3-5 Days' THEN 2
        WHEN v.transit_bucket = '6-8 Days' THEN 3
        WHEN v.transit_bucket = '>8 Days' THEN 4
        ELSE 5
    END;

-- ====================================================================
-- 3. CARRIER SLA PERFORMANCE & BREACH PROFILES
-- ====================================================================
SELECT 
    ca.carrier_id,
    ca.carrier_name,
    ca.sla_days AS carrier_contract_sla,
    COUNT(s.shipment_id) AS shipments_handled,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
    SUM(CASE WHEN s.delay_days = 0 THEN 1 ELSE 0 END) AS on_time_count,
    ROUND((SUM(CASE WHEN s.delay_days = 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
    SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed_count,
    ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS delay_rate_pct,
    SUM(CASE WHEN s.delay_days >= 3 THEN 1 ELSE 0 END) AS severe_breach_count,
    ROUND((SUM(CASE WHEN s.delay_days >= 3 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS severe_breach_rate_pct
FROM stg_clean_shipping s
JOIN carriers ca ON s.carrier_id = ca.carrier_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY ca.carrier_id, ca.carrier_name, ca.sla_days
ORDER BY on_time_rate_pct DESC;

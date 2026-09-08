-- ====================================================================
-- SCRIPT: 11_regional_analysis.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Cross-Regional Performance, Fulfillment Discrepancies, & Vehicle Demand Ratios
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. REGIONAL EXECUTIVE SCORECARD
-- Aggregates Revenue, Units, CSAT, On-Time SLA, and Repeat Purchase Rates
-- ====================================================================
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_cnt
    FROM stg_clean_orders
    GROUP BY customer_id
),
regional_repeat_metrics AS (
    SELECT 
        o.order_region,
        COUNT(DISTINCT o.customer_id) AS total_active_customers,
        SUM(CASE WHEN coc.order_cnt > 1 THEN 1 ELSE 0 END) AS repeat_buyer_orders,
        COUNT(o.order_id) AS total_orders
    FROM stg_clean_orders o
    JOIN customer_order_counts coc ON o.customer_id = coc.customer_id
    GROUP BY o.order_region
),
regional_fulfillment_metrics AS (
    SELECT 
        o.order_region,
        COUNT(s.shipment_id) AS total_shipments,
        SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) AS on_time_shipments,
        SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed_shipments,
        ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
        ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
        ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
        ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS delay_rate_pct,
        ROUND(AVG(f.rating), 2) AS avg_csat_rating
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY o.order_region
)
SELECT 
    o.order_region,
    COUNT(o.order_id) AS order_volume,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    ROUND((SUM(o.net_sales) / (SELECT SUM(net_sales) FROM stg_clean_orders)) * 100, 2) AS revenue_share_pct,
    ROUND(AVG(o.net_sales), 2) AS aov,
    rfm.avg_delivery_days,
    rfm.avg_delay_days,
    rfm.on_time_rate_pct,
    rfm.delay_rate_pct,
    rfm.avg_csat_rating,
    rrm.total_active_customers,
    ROUND((rrm.repeat_buyer_orders / rrm.total_orders) * 100, 2) AS repeat_order_rate_pct
FROM stg_clean_orders o
JOIN regional_fulfillment_metrics rfm ON o.order_region = rfm.order_region
JOIN regional_repeat_metrics rrm ON o.order_region = rrm.order_region
GROUP BY o.order_region, rfm.avg_delivery_days, rfm.avg_delay_days, rfm.on_time_rate_pct, rfm.delay_rate_pct, rfm.avg_csat_rating, rrm.total_active_customers, rrm.repeat_buyer_orders, rrm.total_orders
ORDER BY total_net_revenue DESC;

-- ====================================================================
-- 2. REGIONAL VEHICLE STYLE DEMAND & DEMAND RATIO
-- Compares relative regional appetite for Vehicle Styles against national baseline
-- Demand Ratio = (Regional Style Share %) / (National Style Share %)
-- ====================================================================
WITH national_style_distribution AS (
    SELECT 
        v.vehicle_style,
        COUNT(o.order_id) AS national_style_orders,
        (COUNT(o.order_id) / (SELECT COUNT(*) FROM stg_clean_orders)) AS national_style_share
    FROM stg_clean_orders o
    JOIN vehicles v ON o.vehicle_id = v.vehicle_id
    GROUP BY v.vehicle_style
),
regional_style_distribution AS (
    SELECT 
        o.order_region,
        v.vehicle_style,
        COUNT(o.order_id) AS regional_style_orders,
        COUNT(o.order_id) / SUM(COUNT(o.order_id)) OVER (PARTITION BY o.order_region) AS regional_style_share
    FROM stg_clean_orders o
    JOIN vehicles v ON o.vehicle_id = v.vehicle_id
    GROUP BY o.order_region, v.vehicle_style
)
SELECT 
    rsd.order_region,
    rsd.vehicle_style,
    rsd.regional_style_orders,
    ROUND(rsd.regional_style_share * 100, 2) AS regional_style_share_pct,
    ROUND(nsd.national_style_share * 100, 2) AS national_style_share_pct,
    ROUND(rsd.regional_style_share / nsd.national_style_share, 2) AS style_demand_index_ratio,
    CASE 
        WHEN (rsd.regional_style_share / nsd.national_style_share) >= 1.20 THEN 'Over-indexing (High Local Affinity)'
        WHEN (rsd.regional_style_share / nsd.national_style_share) <= 0.80 THEN 'Under-indexing (Low Local Affinity)'
        ELSE 'Neutral Affinity'
    END AS regional_affinity_classification
FROM regional_style_distribution rsd
JOIN national_style_distribution nsd ON rsd.vehicle_style = nsd.vehicle_style
ORDER BY rsd.order_region ASC, style_demand_index_ratio DESC;

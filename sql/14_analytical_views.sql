-- ====================================================================
-- SCRIPT: 14_analytical_views.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Standardized Production Analytical Views for BI & Reporting
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- --------------------------------------------------------------------
-- VIEW 1: vw_quarterly_sales_performance
-- Executive scorecard tracking revenue, order growth, CSAT, and SLA
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_quarterly_sales_performance AS
WITH quarterly_base AS (
    SELECT 
        CONCAT('2024-Q', QUARTER(o.order_date)) AS sales_quarter,
        QUARTER(o.order_date) AS quarter_num,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS total_units,
        ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
        ROUND(AVG(f.rating), 2) AS avg_csat_score,
        ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_delivery_pct,
        ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY CONCAT('2024-Q', QUARTER(o.order_date)), QUARTER(o.order_date)
),
quarterly_repeat AS (
    SELECT 
        CONCAT('2024-Q', QUARTER(o.order_date)) AS sales_quarter,
        ROUND(
            (SUM(CASE WHEN coc.order_count > 1 THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 2
        ) AS repeat_order_rate_pct
    FROM stg_clean_orders o
    JOIN (
        SELECT customer_id, COUNT(order_id) AS order_count 
        FROM stg_clean_orders 
        GROUP BY customer_id
    ) coc ON o.customer_id = coc.customer_id
    GROUP BY CONCAT('2024-Q', QUARTER(o.order_date))
)
SELECT 
    qb.sales_quarter,
    qb.total_orders,
    qb.total_units,
    qb.total_net_revenue,
    ROUND(
        ((qb.total_net_revenue - LAG(qb.total_net_revenue, 1) OVER (ORDER BY qb.quarter_num)) / 
        LAG(qb.total_net_revenue, 1) OVER (ORDER BY qb.quarter_num)) * 100, 2
    ) AS qoq_revenue_growth_pct,
    qb.on_time_delivery_pct,
    qb.avg_delivery_days,
    qb.avg_csat_score,
    qr.repeat_order_rate_pct
FROM quarterly_base qb
JOIN quarterly_repeat qr ON qb.sales_quarter = qr.sales_quarter;

-- --------------------------------------------------------------------
-- VIEW 2: vw_customer_retention
-- Customer-level lifetime metrics, retention status, and sentiment
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_retention AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.region,
    c.customer_segment,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS latest_order_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units,
    ROUND(SUM(o.net_sales), 2) AS total_revenue,
    CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'Repeat Buyer' ELSE 'One-Time Buyer' END AS repeat_status,
    ROUND(AVG(f.rating), 2) AS avg_customer_rating,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days_experienced
FROM stg_clean_customers c
JOIN stg_clean_orders o ON c.customer_id = o.customer_id
JOIN stg_clean_shipping s ON o.order_id = s.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY c.customer_id, c.customer_name, c.region, c.customer_segment;

-- --------------------------------------------------------------------
-- VIEW 3: vw_delivery_sla
-- Order-level fulfillment, carrier performance, and SLA status
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_delivery_sla AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_region,
    dc.center_name AS dispatch_center,
    ca.carrier_name AS carrier,
    s.dispatch_date,
    s.promised_delivery_date,
    s.actual_delivery_date,
    s.delivery_days,
    s.delay_days,
    s.delivery_status AS sla_status,
    s.transit_bucket
FROM stg_clean_orders o
JOIN stg_clean_shipping s ON o.order_id = s.order_id
JOIN dispatch_centers dc ON s.dispatch_center_id = dc.dispatch_center_id
JOIN carriers ca ON s.carrier_id = ca.carrier_id;

-- --------------------------------------------------------------------
-- VIEW 4: vw_vehicle_performance
-- Granular vehicle portfolio metrics across model, class, style, and region
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vehicle_performance AS
WITH customer_order_counts AS (
    SELECT customer_id, COUNT(order_id) AS order_cnt FROM stg_clean_orders GROUP BY customer_id
)
SELECT 
    v.vehicle_id,
    v.vehicle_model,
    v.vehicle_class,
    v.vehicle_style,
    v.brand,
    o.order_region,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units_sold,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    ROUND(AVG(o.discount / (o.list_price * o.quantity)) * 100, 2) AS avg_discount_pct,
    ROUND(AVG(f.rating), 2) AS avg_rating,
    ROUND(
        (SUM(CASE WHEN coc.order_cnt > 1 THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 2
    ) AS repeat_order_rate_pct
FROM vehicles v
JOIN stg_clean_orders o ON v.vehicle_id = o.vehicle_id
JOIN customer_order_counts coc ON o.customer_id = coc.customer_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY v.vehicle_id, v.vehicle_model, v.vehicle_class, v.vehicle_style, v.brand, o.order_region;

-- --------------------------------------------------------------------
-- VIEW 5: vw_dispatch_center_performance
-- Dispatch center operations, delay share, and bottleneck rankings
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dispatch_center_performance AS
WITH dc_metrics AS (
    SELECT 
        dc.dispatch_center_id,
        dc.center_name,
        dc.region,
        dc.city,
        dc.capacity,
        COUNT(s.shipment_id) AS total_shipments,
        SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS late_shipments,
        ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS delay_pct,
        ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
        SUM(s.delay_days) AS total_delay_days
    FROM dispatch_centers dc
    JOIN stg_clean_shipping s ON dc.dispatch_center_id = s.dispatch_center_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY dc.dispatch_center_id, dc.center_name, dc.region, dc.city, dc.capacity
)
SELECT 
    dispatch_center_id,
    center_name,
    region,
    city,
    capacity,
    total_shipments,
    late_shipments,
    delay_pct,
    avg_delay_days,
    total_delay_days,
    ROUND(
        (total_delay_days / (SELECT SUM(delay_days) FROM stg_clean_shipping WHERE delivery_status != 'Cancelled')) * 100, 2
    ) AS network_delay_share_pct,
    RANK() OVER (ORDER BY total_delay_days DESC) AS bottleneck_rank
FROM dc_metrics;

-- Validation of the 5 views
SELECT 'vw_quarterly_sales_performance' AS view_name, COUNT(*) AS row_count FROM vw_quarterly_sales_performance
UNION ALL SELECT 'vw_customer_retention', COUNT(*) FROM vw_customer_retention
UNION ALL SELECT 'vw_delivery_sla', COUNT(*) FROM vw_delivery_sla
UNION ALL SELECT 'vw_vehicle_performance', COUNT(*) FROM vw_vehicle_performance
UNION ALL SELECT 'vw_dispatch_center_performance', COUNT(*) FROM vw_dispatch_center_performance;

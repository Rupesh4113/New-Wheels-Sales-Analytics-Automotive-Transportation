-- ====================================================================
-- SCRIPT: 10_vehicle_analysis.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Vehicle Portfolio Matrix, Margin/Discount Dynamics, & Dispatch Bottlenecks
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- PART A: DISPATCH CENTER BOTTLENECK & LATENCY CONCENTRATION ANALYSIS
-- Quantifies which centers drive disproportionate network delay days
-- ====================================================================
WITH dc_delay_metrics AS (
    SELECT 
        dc.dispatch_center_id,
        dc.center_name,
        dc.region,
        dc.city,
        dc.capacity,
        COUNT(s.shipment_id) AS total_shipments,
        SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS late_shipments,
        ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS late_shipment_pct,
        ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
        SUM(CASE WHEN s.delay_days >= 3 THEN 1 ELSE 0 END) AS severe_sla_breach_count,
        ROUND((SUM(CASE WHEN s.delay_days >= 3 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS severe_sla_breach_pct,
        SUM(s.delay_days) AS center_cumulative_delay_days
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
    late_shipment_pct,
    avg_delay_days,
    severe_sla_breach_pct,
    center_cumulative_delay_days,
    ROUND(
        (center_cumulative_delay_days / (SELECT SUM(delay_days) FROM stg_clean_shipping WHERE delivery_status != 'Cancelled')) * 100, 2
    ) AS share_of_total_network_delays_pct,
    RANK() OVER (ORDER BY center_cumulative_delay_days DESC) AS delay_volume_rank,
    CASE 
        WHEN (center_cumulative_delay_days / (SELECT SUM(delay_days) FROM stg_clean_shipping WHERE delivery_status != 'Cancelled')) >= 0.20 THEN 'Severe Bottleneck Tier 1'
        WHEN (center_cumulative_delay_days / (SELECT SUM(delay_days) FROM stg_clean_shipping WHERE delivery_status != 'Cancelled')) >= 0.08 THEN 'Moderate Bottleneck Tier 2'
        ELSE 'Stable Operational Tier 3'
    END AS operational_risk_tier
FROM dc_delay_metrics
ORDER BY delay_volume_rank ASC;

-- ====================================================================
-- PART B: VEHICLE PERFORMANCE MATRIX & COMMERCIAL MARGIN PROFILES
-- ====================================================================
WITH vehicle_summary AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_model,
        v.brand,
        v.vehicle_class,
        v.vehicle_style,
        v.list_price,
        v.cost_price,
        ROUND(v.list_price - v.cost_price, 2) AS unit_gross_margin,
        ROUND(((v.list_price - v.cost_price) / v.list_price) * 100, 2) AS gross_margin_pct,
        COUNT(o.order_id) AS total_orders,
        SUM(o.quantity) AS total_units_sold,
        ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
        ROUND(AVG(o.discount / (o.list_price * o.quantity)) * 100, 2) AS avg_discount_pct,
        ROUND(AVG(f.rating), 2) AS avg_csat_rating,
        ROUND(AVG(s.delivery_days), 1) AS avg_delivery_days,
        ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 2) AS delay_rate_pct
    FROM vehicles v
    JOIN stg_clean_orders o ON v.vehicle_id = o.vehicle_id
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
    GROUP BY v.vehicle_id, v.vehicle_model, v.brand, v.vehicle_class, v.vehicle_style, v.list_price, v.cost_price
),
overall_benchmarks AS (
    SELECT 
        AVG(total_net_revenue) AS benchmark_avg_revenue,
        AVG(avg_csat_rating) AS benchmark_avg_csat
    FROM vehicle_summary
)
SELECT 
    vs.vehicle_id,
    vs.vehicle_model,
    vs.brand,
    vs.vehicle_class,
    vs.vehicle_style,
    vs.list_price,
    vs.unit_gross_margin,
    vs.gross_margin_pct,
    vs.total_orders,
    vs.total_units_sold,
    vs.total_net_revenue,
    vs.avg_discount_pct,
    vs.avg_csat_rating,
    vs.delay_rate_pct,
    CASE 
        WHEN vs.total_net_revenue >= b.benchmark_avg_revenue AND vs.avg_csat_rating >= b.benchmark_avg_csat THEN 'Star Performer (High Sales, High CSAT)'
        WHEN vs.total_net_revenue >= b.benchmark_avg_revenue AND vs.avg_csat_rating < b.benchmark_avg_csat THEN 'At-Risk Pillar (High Sales, Low CSAT)'
        WHEN vs.total_net_revenue < b.benchmark_avg_revenue AND vs.avg_csat_rating >= b.benchmark_avg_csat THEN 'Niche Opportunity (Low Sales, High CSAT)'
        ELSE 'Underperforming / Problem Child (Low Sales, Low CSAT)'
    END AS strategic_portfolio_quadrant
FROM vehicle_summary vs
CROSS JOIN overall_benchmarks b
ORDER BY vs.total_net_revenue DESC;

-- ====================================================================
-- PART C: TOP 3 BEST-SELLING & TOP 3 HIGHEST-RATED VEHICLE MODELS
-- ====================================================================
-- Best-Selling Models by Net Revenue
SELECT 
    'Top 3 Revenue Drivers' AS category,
    v.vehicle_model,
    v.brand,
    v.vehicle_class,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.net_sales), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS avg_csat
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY v.vehicle_model, v.brand, v.vehicle_class
ORDER BY total_revenue DESC
LIMIT 3;

-- Highest-Rated Models (Minimum 50 ratings)
SELECT 
    'Top 3 Customer Favorites' AS category,
    v.vehicle_model,
    v.brand,
    v.vehicle_class,
    COUNT(f.rating) AS total_reviews,
    ROUND(AVG(f.rating), 2) AS avg_csat,
    ROUND(SUM(o.net_sales), 2) AS total_revenue
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY v.vehicle_model, v.brand, v.vehicle_class
HAVING COUNT(f.rating) >= 50
ORDER BY avg_csat DESC
LIMIT 3;

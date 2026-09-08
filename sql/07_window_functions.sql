-- ====================================================================
-- SCRIPT: 07_window_functions.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Advanced Window Function Analysis (LAG, LEAD, ROW_NUMBER, RANK, DENSE_RANK)
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. LAG(): QUARTER-OVER-QUARTER (QoQ) PERFORMANCE EVOLUTION
-- Calculates QoQ Revenue, Order, Unit, CSAT, and On-Time Delivery Deltas
-- ====================================================================
WITH quarterly_metrics AS (
    SELECT 
        CONCAT('2024-Q', QUARTER(o.order_date)) AS quarter_name,
        QUARTER(o.order_date) AS qtr_num,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS total_units,
        ROUND(SUM(o.net_sales), 2) AS net_revenue,
        ROUND(AVG(f.rating), 2) AS avg_csat,
        ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
        ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY CONCAT('2024-Q', QUARTER(o.order_date)), QUARTER(o.order_date)
)
SELECT 
    quarter_name,
    total_orders,
    ROUND(((total_orders - LAG(total_orders, 1) OVER (ORDER BY qtr_num)) / LAG(total_orders, 1) OVER (ORDER BY qtr_num)) * 100, 2) AS qoq_order_growth_pct,
    total_units,
    ROUND(((total_units - LAG(total_units, 1) OVER (ORDER BY qtr_num)) / LAG(total_units, 1) OVER (ORDER BY qtr_num)) * 100, 2) AS qoq_unit_growth_pct,
    net_revenue,
    ROUND(((net_revenue - LAG(net_revenue, 1) OVER (ORDER BY qtr_num)) / LAG(net_revenue, 1) OVER (ORDER BY qtr_num)) * 100, 2) AS qoq_revenue_growth_pct,
    avg_csat,
    ROUND(avg_csat - LAG(avg_csat, 1) OVER (ORDER BY qtr_num), 2) AS qoq_csat_absolute_change,
    on_time_rate_pct,
    ROUND(on_time_rate_pct - LAG(on_time_rate_pct, 1) OVER (ORDER BY qtr_num), 2) AS qoq_on_time_rate_change_pct_pts,
    avg_delivery_days,
    ROUND(avg_delivery_days - LAG(avg_delivery_days, 1) OVER (ORDER BY qtr_num), 2) AS qoq_delivery_days_change
FROM quarterly_metrics
ORDER BY qtr_num ASC;

-- ====================================================================
-- 2. LEAD(): CUSTOMER SUBSEQUENT ORDER BEHAVIOR & REPURCHASE INTERVALS
-- Identifies purchase cadence, next order dates, and delivery impact on next purchase
-- ====================================================================
WITH customer_order_timeline AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.order_date,
        s.delivery_status,
        s.delay_days,
        LEAD(o.order_id, 1) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date ASC, o.order_id ASC
        ) AS next_order_id,
        LEAD(o.order_date, 1) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date ASC, o.order_id ASC
        ) AS next_order_date
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
)
SELECT 
    customer_id,
    order_id,
    order_date,
    delivery_status,
    delay_days,
    next_order_id,
    next_order_date,
    DATEDIFF(next_order_date, order_date) AS days_to_next_purchase,
    CASE 
        WHEN next_order_id IS NOT NULL THEN 'Re-purchased'
        ELSE 'Churned / No Repurchase'
    END AS repurchase_status
FROM customer_order_timeline
WHERE order_id IN (SELECT MIN(order_id) FROM stg_clean_orders GROUP BY customer_id)
LIMIT 20;

-- 2.1 Lead-Derived Repurchase Behavior Grouped by Prior Delivery Performance
WITH customer_order_timeline AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.order_date,
        s.transit_bucket,
        s.delivery_status,
        s.delay_days,
        LEAD(o.order_id, 1) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date ASC, o.order_id ASC
        ) AS next_order_id,
        DATEDIFF(
            LEAD(o.order_date, 1) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC, o.order_id ASC),
            o.order_date
        ) AS days_until_repurchase
    FROM stg_clean_orders o
    JOIN stg_clean_shipping s ON o.order_id = s.order_id
    WHERE s.delivery_status != 'Cancelled'
)
SELECT 
    transit_bucket,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN next_order_id IS NOT NULL THEN 1 ELSE 0 END) AS orders_followed_by_repurchase,
    ROUND((SUM(CASE WHEN next_order_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(order_id)) * 100, 2) AS subsequent_repurchase_rate_pct,
    ROUND(AVG(days_until_repurchase), 1) AS avg_days_to_repurchase
FROM customer_order_timeline
GROUP BY transit_bucket
ORDER BY subsequent_repurchase_rate_pct DESC;

-- ====================================================================
-- 3. ROW_NUMBER(): TOP VEHICLE PER REGION & MOST RECENT CUSTOMER TOUCHPOINT
-- ====================================================================

-- 3.1 Top Performing Vehicle Model in Each Geographic Region by Net Revenue
WITH regional_vehicle_performance AS (
    SELECT 
        o.order_region,
        v.vehicle_model,
        v.vehicle_class,
        COUNT(o.order_id) AS order_volume,
        ROUND(SUM(o.net_sales), 2) AS total_regional_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY o.order_region 
            ORDER BY SUM(o.net_sales) DESC
        ) AS rank_in_region
    FROM stg_clean_orders o
    JOIN vehicles v ON o.vehicle_id = v.vehicle_id
    GROUP BY o.order_region, v.vehicle_model, v.vehicle_class
)
SELECT 
    order_region,
    rank_in_region,
    vehicle_model,
    vehicle_class,
    order_volume,
    total_regional_revenue
FROM regional_vehicle_performance
WHERE rank_in_region <= 3
ORDER BY order_region ASC, rank_in_region ASC;

-- 3.2 Most Recent Order and Latest Feedback Per Customer
WITH customer_order_ranked AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.region,
        o.order_id,
        o.order_date,
        o.net_sales,
        f.rating,
        f.satisfaction_category,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date DESC, o.order_id DESC
        ) AS recency_rank
    FROM stg_clean_customers c
    JOIN stg_clean_orders o ON c.customer_id = o.customer_id
    LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
)
SELECT 
    customer_id,
    customer_name,
    region,
    order_id AS latest_order_id,
    order_date AS latest_order_date,
    net_sales AS latest_net_sales,
    rating AS latest_rating,
    satisfaction_category AS latest_sentiment
FROM customer_order_ranked
WHERE recency_rank = 1
LIMIT 15;

-- ====================================================================
-- 4. RANK() & DENSE_RANK(): BENCHMARKING MODELS, REGIONS, & DISPATCH CENTERS
-- ====================================================================

-- 4.1 Ranking Vehicle Models by Revenue (with Ties Handled via DENSE_RANK)
SELECT 
    v.vehicle_model,
    v.vehicle_class,
    v.brand,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    RANK() OVER (ORDER BY SUM(o.net_sales) DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY SUM(o.net_sales) DESC) AS revenue_dense_rank
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_model, v.vehicle_class, v.brand
ORDER BY revenue_rank ASC;

-- 4.2 Ranking Dispatch Centers by Cumulative Delay Impact & Bottleneck Contribution
WITH dc_delay_summary AS (
    SELECT 
        dc.dispatch_center_id,
        dc.center_name,
        dc.region,
        COUNT(s.shipment_id) AS shipments_handled,
        SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed_shipments,
        ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS delay_rate_pct,
        SUM(s.delay_days) AS total_delay_days,
        ROUND(AVG(s.delay_days), 2) AS avg_delay_days
    FROM stg_clean_shipping s
    JOIN dispatch_centers dc ON s.dispatch_center_id = dc.dispatch_center_id
    WHERE s.delivery_status != 'Cancelled'
    GROUP BY dc.dispatch_center_id, dc.center_name, dc.region
)
SELECT 
    dispatch_center_id,
    center_name,
    region,
    shipments_handled,
    delayed_shipments,
    delay_rate_pct,
    total_delay_days,
    ROUND((total_delay_days / (SELECT SUM(delay_days) FROM stg_clean_shipping WHERE delivery_status != 'Cancelled')) * 100, 2) AS network_delay_share_pct,
    RANK() OVER (ORDER BY total_delay_days DESC) AS delay_volume_rank,
    DENSE_RANK() OVER (ORDER BY delay_rate_pct DESC) AS delay_rate_dense_rank
FROM dc_delay_summary
ORDER BY delay_volume_rank ASC;

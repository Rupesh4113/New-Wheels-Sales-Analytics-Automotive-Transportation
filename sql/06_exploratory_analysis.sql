-- ====================================================================
-- SCRIPT: 06_exploratory_analysis.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Core Exploratory Data Analysis across Sales, Customer, Fulfillment
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- SECTION 1: OVERALL SALES & COMMERCIAL METRICS
-- ====================================================================

-- 1.1 High-Level Sales Baseline KPIs
SELECT 
    'Executive Summary Baseline' AS metric_level,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN order_status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(list_price * quantity), 2) AS gross_revenue,
    ROUND(SUM(discount), 2) AS total_discount_amount,
    ROUND(SUM(net_sales), 2) AS total_net_revenue,
    ROUND(AVG(net_sales), 2) AS avg_order_value_aov,
    ROUND(SUM(net_sales) / SUM(quantity), 2) AS avg_selling_price_asp,
    ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 2) AS overall_discount_rate_pct
FROM stg_clean_orders;

-- 1.2 Sales by Quarter (Investigating Deterioration)
SELECT 
    CONCAT('2024-Q', QUARTER(order_date)) AS sales_quarter,
    COUNT(order_id) AS order_volume,
    SUM(quantity) AS units_sold,
    ROUND(SUM(net_sales), 2) AS net_revenue,
    ROUND(AVG(net_sales), 2) AS aov,
    ROUND(SUM(discount), 2) AS total_discount,
    ROUND((SUM(discount) / SUM(list_price * quantity)) * 100, 2) AS avg_discount_rate_pct
FROM stg_clean_orders
GROUP BY CONCAT('2024-Q', QUARTER(order_date))
ORDER BY sales_quarter ASC;

-- 1.3 Sales by Month
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    COUNT(order_id) AS order_volume,
    SUM(quantity) AS units_sold,
    ROUND(SUM(net_sales), 2) AS net_revenue,
    ROUND(AVG(net_sales), 2) AS aov
FROM stg_clean_orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month ASC;

-- 1.4 Sales by Region
SELECT 
    order_region,
    COUNT(order_id) AS order_volume,
    SUM(quantity) AS units_sold,
    ROUND(SUM(net_sales), 2) AS net_revenue,
    ROUND((SUM(net_sales) / (SELECT SUM(net_sales) FROM stg_clean_orders)) * 100, 2) AS regional_revenue_share_pct,
    ROUND(AVG(net_sales), 2) AS aov
FROM stg_clean_orders
GROUP BY order_region
ORDER BY net_revenue DESC;

-- 1.5 Sales by Vehicle Class & Style
SELECT 
    v.vehicle_class,
    v.vehicle_style,
    COUNT(o.order_id) AS order_volume,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.net_sales), 2) AS net_revenue,
    ROUND(AVG(o.net_sales), 2) AS aov,
    ROUND((SUM(o.discount) / SUM(o.list_price * o.quantity)) * 100, 2) AS avg_discount_pct
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_class, v.vehicle_style
ORDER BY net_revenue DESC;

-- 1.6 Sales by Vehicle Model (Top & Bottom Performers)
SELECT 
    v.vehicle_model,
    v.brand,
    v.vehicle_class,
    COUNT(o.order_id) AS order_volume,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.net_sales), 2) AS net_revenue,
    ROUND(AVG(v.list_price), 2) AS list_price,
    ROUND(AVG(o.discount / (o.list_price * o.quantity)) * 100, 2) AS avg_discount_pct
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_model, v.brand, v.vehicle_class
ORDER BY net_revenue DESC;

-- ====================================================================
-- SECTION 2: CUSTOMER & SATISFACTION (CSAT) METRICS
-- ====================================================================

-- 2.1 Customer Base & Repeat Purchasing Overview
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count
    FROM stg_clean_orders
    GROUP BY customer_id
)
SELECT 
    (SELECT COUNT(*) FROM stg_clean_customers) AS total_registered_customers,
    COUNT(customer_id) AS purchasing_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_buyers,
    ROUND((SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(customer_id)) * 100, 2) AS repeat_purchase_rate_pct
FROM customer_order_counts;

-- 2.2 Customer Feedback Rating Distribution
SELECT 
    COALESCE(CAST(rating AS CHAR), 'Unrated') AS rating_score,
    satisfaction_category,
    COUNT(*) AS feedback_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM stg_clean_feedback) * 100, 2) AS pct_of_responses
FROM stg_clean_feedback
GROUP BY rating, satisfaction_category
ORDER BY rating DESC;

-- 2.3 Customer Satisfaction (CSAT) by Quarter
SELECT 
    CONCAT('2024-Q', QUARTER(o.order_date)) AS sales_quarter,
    COUNT(o.order_id) AS total_orders,
    COUNT(f.rating) AS total_rated_orders,
    ROUND(AVG(f.rating), 2) AS average_csat,
    ROUND(SUM(CASE WHEN f.rating >= 4 THEN 1 ELSE 0 END) / COUNT(f.rating) * 100, 2) AS csat_positive_pct_4_5_stars,
    ROUND(SUM(CASE WHEN f.rating <= 2 THEN 1 ELSE 0 END) / COUNT(f.rating) * 100, 2) AS csat_negative_pct_1_2_stars
FROM stg_clean_orders o
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY CONCAT('2024-Q', QUARTER(o.order_date))
ORDER BY sales_quarter ASC;

-- 2.4 CSAT by Delivery Transit Bucket
SELECT 
    s.transit_bucket,
    COUNT(o.order_id) AS shipment_volume,
    ROUND(AVG(s.delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(s.delay_days), 1) AS avg_delay_days,
    COUNT(f.rating) AS rated_count,
    ROUND(AVG(f.rating), 2) AS avg_csat_rating,
    ROUND(SUM(CASE WHEN f.rating <= 2 THEN 1 ELSE 0 END) / COUNT(f.rating) * 100, 2) AS dissatisfied_pct
FROM stg_clean_orders o
JOIN stg_clean_shipping s ON o.order_id = s.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY s.transit_bucket
ORDER BY avg_delivery_days ASC;

-- 2.5 CSAT by Vehicle Class
SELECT 
    v.vehicle_class,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS avg_csat,
    ROUND(AVG(s.delivery_days), 1) AS avg_delivery_days
FROM stg_clean_orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
JOIN stg_clean_shipping s ON o.order_id = s.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
GROUP BY v.vehicle_class
ORDER BY avg_csat DESC;

-- ====================================================================
-- SECTION 3: FULFILLMENT & LOGISTICS SLA PERFORMANCE
-- ====================================================================

-- 3.1 Overall Network Fulfillment KPIs
SELECT 
    COUNT(shipment_id) AS total_shipments,
    SUM(CASE WHEN delivery_status = 'On-Time' THEN 1 ELSE 0 END) AS on_time_shipments,
    SUM(CASE WHEN delivery_status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_shipments,
    SUM(CASE WHEN delivery_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_shipments,
    ROUND((SUM(CASE WHEN delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(shipment_id)) * 100, 2) AS on_time_delivery_rate_pct,
    ROUND((SUM(CASE WHEN delivery_status = 'Delayed' THEN 1 ELSE 0 END) / COUNT(shipment_id)) * 100, 2) AS late_delivery_rate_pct,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(CASE WHEN delay_days > 0 THEN delay_days ELSE NULL END), 2) AS avg_delay_days_when_late
FROM stg_clean_shipping
WHERE delivery_status != 'Cancelled';

-- 3.2 Fulfillment Performance by Carrier
SELECT 
    ca.carrier_id,
    ca.carrier_name,
    ca.sla_days AS promised_sla_days,
    COUNT(s.shipment_id) AS total_shipments,
    ROUND(AVG(s.delivery_days), 2) AS avg_actual_delivery_days,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
    ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
    ROUND((SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS delay_rate_pct
FROM stg_clean_shipping s
JOIN carriers ca ON s.carrier_id = ca.carrier_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY ca.carrier_id, ca.carrier_name, ca.sla_days
ORDER BY on_time_rate_pct DESC;

-- 3.3 Fulfillment Performance by Dispatch Center
SELECT 
    dc.dispatch_center_id,
    dc.center_name,
    dc.region,
    COUNT(s.shipment_id) AS shipments_handled,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(s.delay_days), 2) AS avg_delay_days,
    ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
    SUM(CASE WHEN s.delay_days > 0 THEN 1 ELSE 0 END) AS delayed_orders_count,
    ROUND(SUM(s.delay_days), 0) AS cumulative_delay_days
FROM stg_clean_shipping s
JOIN dispatch_centers dc ON s.dispatch_center_id = dc.dispatch_center_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY dc.dispatch_center_id, dc.center_name, dc.region
ORDER BY cumulative_delay_days DESC;

-- 3.4 Delivery Performance by Customer Region
SELECT 
    o.order_region,
    COUNT(s.shipment_id) AS regional_orders,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND((SUM(CASE WHEN s.delivery_status = 'On-Time' THEN 1 ELSE 0 END) / COUNT(s.shipment_id)) * 100, 2) AS on_time_rate_pct,
    ROUND(AVG(f.rating), 2) AS avg_regional_csat
FROM stg_clean_orders o
JOIN stg_clean_shipping s ON o.order_id = s.order_id
LEFT JOIN stg_clean_feedback f ON o.order_id = f.order_id
WHERE s.delivery_status != 'Cancelled'
GROUP BY o.order_region
ORDER BY on_time_rate_pct ASC;

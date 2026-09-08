-- ====================================================================
-- SCRIPT: 15_query_optimization.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Index Design, Query Execution Plans (EXPLAIN), & Performance Benchmarking
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- ====================================================================
-- 1. INSPECT EXECUTION PLAN PRIOR TO CUSTOM INDEXING (BASELINE)
-- ====================================================================
EXPLAIN ANALYZE
SELECT 
    o.order_region,
    v.vehicle_class,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(f.rating), 2) AS avg_csat_rating
FROM orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
JOIN shipping s ON o.order_id = s.order_id
LEFT JOIN customer_feedback f ON o.order_id = f.order_id
WHERE o.order_date BETWEEN '2024-04-01' AND '2024-12-31'
  AND s.delivery_status != 'Cancelled'
GROUP BY o.order_region, v.vehicle_class
ORDER BY total_net_revenue DESC;

-- ====================================================================
-- 2. CREATE TARGETED COMPOSITE, COVERING, AND FOREIGN KEY INDEXES
-- ====================================================================

-- Index 1: Orders - Date range filtering combined with foreign keys and dimensions
CREATE INDEX idx_orders_date_region_veh ON orders (order_date, order_region, vehicle_id);

-- Index 2: Orders - Customer order recency and customer-level joins
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date);

-- Index 3: Shipping - Fast join on order_id with status filtering
CREATE INDEX idx_shipping_order_status ON shipping (order_id, delivery_status);

-- Index 4: Shipping - Dispatch center bottleneck and delay auditing
CREATE INDEX idx_shipping_dc_delay ON shipping (dispatch_center_id, delay_days, delivery_days);

-- Index 5: Feedback - Order covering index with rating
CREATE INDEX idx_feedback_order_rating ON customer_feedback (order_id, rating);

-- Index 6: Customers - Regional demographic lookups
CREATE INDEX idx_customers_region_seg ON customers (region, customer_segment);

-- ====================================================================
-- 3. INSPECT EXECUTION PLAN AFTER INDEX OPTIMIZATION
-- ====================================================================
EXPLAIN ANALYZE
SELECT 
    o.order_region,
    v.vehicle_class,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(f.rating), 2) AS avg_csat_rating
FROM orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
JOIN shipping s ON o.order_id = s.order_id
LEFT JOIN customer_feedback f ON o.order_id = f.order_id
WHERE o.order_date BETWEEN '2024-04-01' AND '2024-12-31'
  AND s.delivery_status != 'Cancelled'
GROUP BY o.order_region, v.vehicle_class
ORDER BY total_net_revenue DESC;

-- Confirm index catalog
SHOW INDEX FROM orders;
SHOW INDEX FROM shipping;
SHOW INDEX FROM customer_feedback;

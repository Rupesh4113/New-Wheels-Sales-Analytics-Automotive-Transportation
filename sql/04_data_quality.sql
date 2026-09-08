-- ====================================================================
-- SCRIPT: 04_data_quality.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Exhaustive Data Quality and Referential Integrity Audit Suite
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- --------------------------------------------------------------------
-- CHECK 1: Completeness Audit (NULLs in Mandatory Primary / Foreign Keys)
-- --------------------------------------------------------------------
SELECT 
    'Mandatory Key Completeness' AS audit_category,
    'orders' AS table_name,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_pks,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_fks,
    SUM(CASE WHEN vehicle_id IS NULL THEN 1 ELSE 0 END) AS null_vehicle_fks,
    SUM(CASE WHEN dispatch_center_id IS NULL THEN 1 ELSE 0 END) AS null_dc_fks
FROM orders
UNION ALL
SELECT 
    'Mandatory Key Completeness',
    'shipping',
    SUM(CASE WHEN shipment_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN carrier_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN dispatch_center_id IS NULL THEN 1 ELSE 0 END)
FROM shipping
UNION ALL
SELECT 
    'Mandatory Key Completeness',
    'customers',
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END),
    0, 0, 0
FROM customers;

-- --------------------------------------------------------------------
-- CHECK 2: Referential Integrity / Orphan Foreign Key Audit
-- --------------------------------------------------------------------
SELECT 
    'Orphan Foreign Keys' AS audit_category,
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 
    'Orphan Foreign Keys',
    'orders -> vehicles',
    COUNT(*)
FROM orders o
LEFT JOIN vehicles v ON o.vehicle_id = v.vehicle_id
WHERE v.vehicle_id IS NULL
UNION ALL
SELECT 
    'Orphan Foreign Keys',
    'orders -> dispatch_centers',
    COUNT(*)
FROM orders o
LEFT JOIN dispatch_centers dc ON o.dispatch_center_id = dc.dispatch_center_id
WHERE dc.dispatch_center_id IS NULL
UNION ALL
SELECT 
    'Orphan Foreign Keys',
    'shipping -> orders',
    COUNT(*)
FROM shipping s
LEFT JOIN orders o ON s.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 
    'Orphan Foreign Keys',
    'shipping -> carriers',
    COUNT(*)
FROM shipping s
LEFT JOIN carriers ca ON s.carrier_id = ca.carrier_id
WHERE ca.carrier_id IS NULL
UNION ALL
SELECT 
    'Orphan Foreign Keys',
    'customer_feedback -> orders',
    COUNT(*)
FROM customer_feedback f
LEFT JOIN orders o ON f.order_id = o.order_id
WHERE o.order_id IS NULL;

-- --------------------------------------------------------------------
-- CHECK 3: Commercial & Financial Domain Validity
-- --------------------------------------------------------------------
SELECT 
    'Financial Sanity' AS audit_category,
    COUNT(*) AS total_anomalies,
    SUM(CASE WHEN net_sales < 0 THEN 1 ELSE 0 END) AS negative_net_sales_count,
    SUM(CASE WHEN discount < 0 THEN 1 ELSE 0 END) AS negative_discount_count,
    SUM(CASE WHEN list_price <= 0 THEN 1 ELSE 0 END) AS invalid_price_count,
    SUM(CASE WHEN discount > (list_price * quantity) THEN 1 ELSE 0 END) AS excessive_discount_count,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS non_positive_quantity_count
FROM orders;

-- --------------------------------------------------------------------
-- CHECK 4: Chronological & Temporal Integrity
-- --------------------------------------------------------------------
SELECT 
    'Temporal Logic' AS audit_category,
    COUNT(*) AS total_checked,
    SUM(CASE WHEN dispatch_date < (SELECT order_date FROM orders o WHERE o.order_id = s.order_id) THEN 1 ELSE 0 END) AS dispatch_before_order,
    SUM(CASE WHEN actual_delivery_date IS NOT NULL AND actual_delivery_date < dispatch_date THEN 1 ELSE 0 END) AS delivery_before_dispatch,
    SUM(CASE WHEN delivery_days < 0 THEN 1 ELSE 0 END) AS negative_delivery_days,
    SUM(CASE WHEN delay_days < 0 THEN 1 ELSE 0 END) AS negative_delay_days
FROM shipping s;

-- --------------------------------------------------------------------
-- CHECK 5: Customer Feedback Rating Integrity & Missing Rating Quantification
-- --------------------------------------------------------------------
SELECT 
    'Rating Sanity & Completeness' AS audit_category,
    COUNT(*) AS total_feedback_records,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS missing_rating_count,
    ROUND(SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS missing_rating_pct,
    SUM(CASE WHEN rating < 1 OR rating > 5 THEN 1 ELSE 0 END) AS out_of_bounds_ratings
FROM customer_feedback;

-- --------------------------------------------------------------------
-- CHECK 6: Natural Key Duplicate Detection
-- --------------------------------------------------------------------
SELECT 
    'Duplicate Orders Audit' AS audit_category,
    customer_id,
    order_date,
    vehicle_id,
    quantity,
    COUNT(*) AS duplicate_occurrences
FROM orders
GROUP BY customer_id, order_date, vehicle_id, quantity
HAVING COUNT(*) > 1;

-- --------------------------------------------------------------------
-- CHECK 7: Shipping Reconciliation (Missing Shipments)
-- --------------------------------------------------------------------
SELECT 
    'Fulfillment Completeness' AS audit_category,
    COUNT(o.order_id) AS orders_without_shipping_record
FROM orders o
LEFT JOIN shipping s ON o.order_id = s.order_id
WHERE s.shipment_id IS NULL;

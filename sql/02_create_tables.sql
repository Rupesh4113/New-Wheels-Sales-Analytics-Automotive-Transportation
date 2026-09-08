-- ====================================================================
-- SCRIPT: 02_create_tables.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Relational DDL with Primary Keys, Foreign Keys, and Constraints
-- ENGINE: MySQL 8.0+
-- ====================================================================

USE new_wheels_db;

-- Drop dependent tables in reverse dependency order
DROP TABLE IF EXISTS customer_feedback;
DROP TABLE IF EXISTS shipping;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS carriers;
DROP TABLE IF EXISTS dispatch_centers;

-- 1. DISPATCH CENTERS
CREATE TABLE dispatch_centers (
    dispatch_center_id INT NOT NULL,
    center_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(10) NOT NULL,
    capacity INT NOT NULL,
    established_date DATE NOT NULL,
    CONSTRAINT pk_dispatch_centers PRIMARY KEY (dispatch_center_id),
    CONSTRAINT chk_dc_capacity CHECK (capacity > 0)
) ENGINE=InnoDB;

-- 2. CARRIERS
CREATE TABLE carriers (
    carrier_id INT NOT NULL,
    carrier_name VARCHAR(100) NOT NULL,
    service_region VARCHAR(50) NOT NULL,
    sla_days INT NOT NULL,
    CONSTRAINT pk_carriers PRIMARY KEY (carrier_id),
    CONSTRAINT chk_carrier_sla CHECK (sla_days BETWEEN 1 AND 14)
) ENGINE=InnoDB;

-- 3. CUSTOMERS
CREATE TABLE customers (
    customer_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    age INT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(10) NOT NULL,
    region VARCHAR(50) NOT NULL,
    customer_segment VARCHAR(50) NOT NULL,
    registration_date DATE NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT chk_customer_age CHECK (age >= 16)
) ENGINE=InnoDB;

-- 4. VEHICLES
CREATE TABLE vehicles (
    vehicle_id INT NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_class VARCHAR(50) NOT NULL,
    vehicle_style VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model_year INT NOT NULL,
    list_price DECIMAL(12, 2) NOT NULL,
    cost_price DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_vehicles PRIMARY KEY (vehicle_id),
    CONSTRAINT chk_vehicle_prices CHECK (list_price >= cost_price AND cost_price > 0)
) ENGINE=InnoDB;

-- 5. ORDERS
CREATE TABLE orders (
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    vehicle_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    list_price DECIMAL(12, 2) NOT NULL,
    discount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    net_sales DECIMAL(12, 2) NOT NULL,
    order_region VARCHAR(50) NOT NULL,
    dispatch_center_id INT NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_dc FOREIGN KEY (dispatch_center_id) REFERENCES dispatch_centers(dispatch_center_id) ON DELETE RESTRICT,
    CONSTRAINT chk_order_qty CHECK (quantity > 0),
    CONSTRAINT chk_order_discount CHECK (discount >= 0.00),
    CONSTRAINT chk_order_net CHECK (net_sales >= 0.00)
) ENGINE=InnoDB;

-- 6. ORDER ITEMS
CREATE TABLE order_items (
    order_item_id INT NOT NULL,
    order_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    discount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. SHIPPING / FULFILLMENT
CREATE TABLE shipping (
    shipment_id INT NOT NULL,
    order_id INT NOT NULL,
    dispatch_center_id INT NOT NULL,
    carrier_id INT NOT NULL,
    dispatch_date DATE NOT NULL,
    shipped_date DATE NOT NULL,
    promised_delivery_date DATE NOT NULL,
    actual_delivery_date DATE NULL,
    delivery_status VARCHAR(30) NOT NULL,
    delivery_days INT NOT NULL DEFAULT 0,
    delay_days INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_shipping PRIMARY KEY (shipment_id),
    CONSTRAINT fk_shipping_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_shipping_dc FOREIGN KEY (dispatch_center_id) REFERENCES dispatch_centers(dispatch_center_id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipping_carrier FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. CUSTOMER FEEDBACK
CREATE TABLE customer_feedback (
    feedback_id INT NOT NULL,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NULL,
    feedback_date DATE NOT NULL,
    satisfaction_category VARCHAR(50) NOT NULL,
    comments TEXT NULL,
    CONSTRAINT pk_customer_feedback PRIMARY KEY (feedback_id),
    CONSTRAINT fk_feedback_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT chk_feedback_rating CHECK (rating IS NULL OR rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

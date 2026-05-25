-- ============================================================
-- SCRIPT 4: ANALYTICAL VIEWS
-- Warehouse Management Practice Database
-- Run against: warehouse_mockup
-- ============================================================

USE warehouse_mockup;
GO

-- ============================================================
-- VIEW 1: STOCK LEVELS
-- Current inventory quantities per product
-- Flags anything at zero stock
-- ============================================================
CREATE VIEW vw_stock_levels AS
SELECT
    p.id AS product_id,
    p.sku,
    p.name AS product_name,
    p.category,
    p.unit_price,
    COALESCE(i.quantity, 0) AS quantity_on_hand,
    COALESCE(i.quantity, 0) * p.unit_price AS stock_value,
    b.bin_code,
    w.name AS warehouse_name,
    CASE
        WHEN COALESCE(i.quantity, 0) = 0 THEN 'Out of Stock'
        WHEN COALESCE(i.quantity, 0) < 10 THEN 'Low Stock'
        WHEN COALESCE(i.quantity, 0) < 50 THEN 'Moderate'
        ELSE 'Well Stocked'
    END AS stock_status
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
LEFT JOIN bin_locations b ON i.bin_location_id = b.id
LEFT JOIN aisles a ON b.aisle_id = a.id
LEFT JOIN zones z ON a.zone_id = z.id
LEFT JOIN warehouses w ON z.warehouse_id = w.id;
GO

-- ============================================================
-- VIEW 2: SUPPLIER PERFORMANCE
-- Average lead time vs actual delivery time per supplier
-- Calculates on-time rate and average days variance
-- ============================================================
CREATE VIEW vw_supplier_performance AS
SELECT
    s.id AS supplier_id,
    s.name AS supplier_name,
    s.country,
    s.lead_time_days AS promised_lead_time,
    COUNT(po.id) AS total_orders,
    SUM(CASE WHEN po.status = 'received' THEN 1 ELSE 0 END) AS received_orders,
    SUM(CASE WHEN po.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    AVG(CASE
        WHEN ins.received_date IS NOT NULL
        THEN DATEDIFF(day, po.order_date, ins.received_date)
    END) AS avg_actual_lead_time,
    AVG(CASE
        WHEN ins.received_date IS NOT NULL
        THEN DATEDIFF(day, po.expected_date, ins.received_date)
    END) AS avg_days_variance,
    SUM(CASE
        WHEN ins.received_date <= po.expected_date THEN 1
        ELSE 0
    END) AS on_time_deliveries,
    CASE
        WHEN COUNT(CASE WHEN po.status = 'received' THEN 1 END) = 0 THEN NULL
        ELSE CAST(
            SUM(CASE WHEN ins.received_date <= po.expected_date THEN 1 ELSE 0 END) * 100.0
            / COUNT(CASE WHEN po.status = 'received' THEN 1 END)
        AS DECIMAL(5,2))
    END AS on_time_rate_pct
FROM suppliers s
LEFT JOIN purchase_orders po ON s.id = po.supplier_id
LEFT JOIN inbound_shipments ins ON po.id = ins.purchase_order_id
GROUP BY s.id, s.name, s.country, s.lead_time_days;
GO

-- ============================================================
-- VIEW 3: EMPLOYEE ACTIVITY
-- Shipments received and stock movements per employee
-- ============================================================
CREATE VIEW vw_employee_activity AS
SELECT
    e.id AS employee_id,
    e.name AS employee_name,
    e.role,
    w.name AS warehouse_name,
    COUNT(DISTINCT ins.id) AS shipments_received,
    COUNT(DISTINCT sm.id) AS stock_movements,
    SUM(CASE WHEN sm.movement_type = 'receive' THEN 1 ELSE 0 END) AS receive_movements,
    SUM(CASE WHEN sm.movement_type = 'pick' THEN 1 ELSE 0 END) AS pick_movements,
    SUM(CASE WHEN sm.movement_type = 'transfer' THEN 1 ELSE 0 END) AS transfer_movements,
    SUM(CASE WHEN sm.movement_type = 'adjustment' THEN 1 ELSE 0 END) AS adjustment_movements
FROM employees e
LEFT JOIN warehouses w ON e.warehouse_id = w.id
LEFT JOIN inbound_shipments ins ON e.id = ins.received_by
LEFT JOIN stock_movements sm ON e.id = sm.moved_by
GROUP BY e.id, e.name, e.role, w.name;
GO

-- ============================================================
-- VIEW 4: ORDER FULFILLMENT
-- Outbound order status tracking with days to ship
-- Flags overdue open orders
-- ============================================================
CREATE VIEW vw_order_fulfillment AS
SELECT
    oo.id AS order_id,
    oo.customer_name,
    w.name AS warehouse_name,
    oo.order_date,
    oo.shipped_date,
    oo.status,
    CASE
        WHEN oo.shipped_date IS NOT NULL
        THEN DATEDIFF(day, oo.order_date, oo.shipped_date)
    END AS days_to_ship,
    CASE
        WHEN oo.status NOT IN ('shipped', 'cancelled') AND DATEDIFF(day, oo.order_date, GETDATE()) > 7
        THEN 'Overdue'
        WHEN oo.status NOT IN ('shipped', 'cancelled')
        THEN 'In Progress'
        ELSE oo.status
    END AS fulfillment_flag,
    COUNT(oi.id) AS total_line_items,
    SUM(oi.quantity) AS total_units_ordered
FROM outbound_orders oo
JOIN warehouses w ON oo.warehouse_id = w.id
LEFT JOIN outbound_order_items oi ON oo.id = oi.outbound_order_id
GROUP BY oo.id, oo.customer_name, w.name, oo.order_date, oo.shipped_date, oo.status;
GO

-- ============================================================
-- VIEW 5: WAREHOUSE THROUGHPUT
-- Monthly inbound vs outbound volume per warehouse
-- ============================================================
CREATE VIEW vw_warehouse_throughput AS
SELECT
    w.name AS warehouse_name,
    YEAR(po.order_date) AS year,
    MONTH(po.order_date) AS month,
    COUNT(DISTINCT po.id) AS inbound_orders,
    SUM(poi.quantity_received) AS units_received,
    SUM(poi.quantity_received * poi.unit_cost) AS inbound_cost
FROM warehouses w
LEFT JOIN purchase_orders po ON w.id = po.warehouse_id AND po.status = 'received'
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
GROUP BY w.name, YEAR(po.order_date), MONTH(po.order_date)

UNION ALL

SELECT
    w.name AS warehouse_name,
    YEAR(oo.order_date) AS year,
    MONTH(oo.order_date) AS month,
    COUNT(DISTINCT oo.id) AS outbound_orders,
    SUM(oi.quantity) AS units_shipped,
    SUM(oi.quantity * p.unit_price) AS outbound_revenue
FROM warehouses w
LEFT JOIN outbound_orders oo ON w.id = oo.warehouse_id AND oo.status = 'shipped'
LEFT JOIN outbound_order_items oi ON oo.id = oi.outbound_order_id
LEFT JOIN products p ON oi.product_id = p.id
GROUP BY w.name, YEAR(oo.order_date), MONTH(oo.order_date);
GO

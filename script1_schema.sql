-- ============================================================
-- SCRIPT 1: SCHEMA
-- Warehouse Management Practice Database
-- Run against: warehouse_mockup
-- ============================================================

USE warehouse_mockup;
GO

-- ============================================================
-- EMPLOYEES
-- Inserted before warehouses since warehouses reference manager_id
-- manager_id is self-referencing, top level managers have NULL
-- ============================================================
CREATE TABLE employees (
    id              INT             PRIMARY KEY,
    name            NVARCHAR(100)   NOT NULL,
    role            NVARCHAR(50)    NOT NULL,
    warehouse_id    INT             NULL,
    manager_id      INT             NULL,
    hire_date       DATE            NOT NULL,
    salary          DECIMAL(10,2)   NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(id)
);
GO

-- ============================================================
-- WAREHOUSES
-- ============================================================
CREATE TABLE warehouses (
    id              INT             PRIMARY KEY,
    name            NVARCHAR(100)   NOT NULL,
    location        NVARCHAR(150)   NOT NULL,
    capacity_sqft   INT             NOT NULL,
    manager_id      INT             NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(id)
);
GO

-- ============================================================
-- Add warehouse_id FK to employees after warehouses table exists
-- ============================================================
ALTER TABLE employees
ADD CONSTRAINT fk_employees_warehouse
FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);
GO

-- ============================================================
-- ZONES
-- ============================================================
CREATE TABLE zones (
    id              INT             PRIMARY KEY,
    warehouse_id    INT             NOT NULL,
    zone_code       NVARCHAR(10)    NOT NULL,
    zone_type       NVARCHAR(20)    NOT NULL CHECK (zone_type IN ('receiving', 'storage', 'shipping')),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);
GO

-- ============================================================
-- AISLES
-- ============================================================
CREATE TABLE aisles (
    id              INT             PRIMARY KEY,
    zone_id         INT             NOT NULL,
    aisle_code      NVARCHAR(10)    NOT NULL,
    FOREIGN KEY (zone_id) REFERENCES zones(id)
);
GO

-- ============================================================
-- BIN LOCATIONS
-- ============================================================
CREATE TABLE bin_locations (
    id              INT             PRIMARY KEY,
    aisle_id        INT             NOT NULL,
    bin_code        NVARCHAR(10)    NOT NULL,
    max_weight_kg   DECIMAL(8,2)    NOT NULL,
    is_active       BIT             NOT NULL DEFAULT 1,
    FOREIGN KEY (aisle_id) REFERENCES aisles(id)
);
GO

-- ============================================================
-- SUPPLIERS
-- ============================================================
CREATE TABLE suppliers (
    id              INT             PRIMARY KEY,
    name            NVARCHAR(100)   NOT NULL,
    contact_email   NVARCHAR(150)   NULL,
    country         NVARCHAR(50)    NOT NULL,
    lead_time_days  INT             NOT NULL
);
GO

-- ============================================================
-- PRODUCTS
-- ============================================================
CREATE TABLE products (
    id              INT             PRIMARY KEY,
    sku             NVARCHAR(20)    NOT NULL UNIQUE,
    name            NVARCHAR(100)   NOT NULL,
    category        NVARCHAR(50)    NOT NULL,
    unit_weight_kg  DECIMAL(8,2)    NOT NULL,
    unit_price      DECIMAL(10,2)   NOT NULL
);
GO

-- ============================================================
-- INVENTORY
-- ============================================================
CREATE TABLE inventory (
    id              INT             PRIMARY KEY,
    bin_location_id INT             NOT NULL,
    product_id      INT             NOT NULL,
    quantity        INT             NOT NULL DEFAULT 0,
    last_updated    DATETIME        NOT NULL,
    FOREIGN KEY (bin_location_id) REFERENCES bin_locations(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
GO

-- ============================================================
-- PURCHASE ORDERS
-- ============================================================
CREATE TABLE purchase_orders (
    id              INT             PRIMARY KEY,
    supplier_id     INT             NOT NULL,
    warehouse_id    INT             NOT NULL,
    order_date      DATE            NOT NULL,
    expected_date   DATE            NOT NULL,
    status          NVARCHAR(20)    NOT NULL CHECK (status IN ('pending', 'in_transit', 'received', 'cancelled')),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);
GO

-- ============================================================
-- PURCHASE ORDER ITEMS
-- ============================================================
CREATE TABLE purchase_order_items (
    id                  INT             PRIMARY KEY,
    purchase_order_id   INT             NOT NULL,
    product_id          INT             NOT NULL,
    quantity_ordered    INT             NOT NULL,
    quantity_received   INT             NOT NULL DEFAULT 0,
    unit_cost           DECIMAL(10,2)   NOT NULL,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
GO

-- ============================================================
-- INBOUND SHIPMENTS
-- ============================================================
CREATE TABLE inbound_shipments (
    id                  INT             PRIMARY KEY,
    purchase_order_id   INT             NOT NULL,
    received_date       DATE            NOT NULL,
    received_by         INT             NOT NULL,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    FOREIGN KEY (received_by) REFERENCES employees(id)
);
GO

-- ============================================================
-- OUTBOUND ORDERS
-- ============================================================
CREATE TABLE outbound_orders (
    id              INT             PRIMARY KEY,
    customer_name   NVARCHAR(100)   NOT NULL,
    warehouse_id    INT             NOT NULL,
    order_date      DATE            NOT NULL,
    shipped_date    DATE            NULL,
    status          NVARCHAR(20)    NOT NULL CHECK (status IN ('pending', 'picking', 'packed', 'shipped', 'cancelled')),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);
GO

-- ============================================================
-- OUTBOUND ORDER ITEMS
-- ============================================================
CREATE TABLE outbound_order_items (
    id                  INT             PRIMARY KEY,
    outbound_order_id   INT             NOT NULL,
    product_id          INT             NOT NULL,
    quantity            INT             NOT NULL,
    bin_location_id     INT             NOT NULL,
    FOREIGN KEY (outbound_order_id) REFERENCES outbound_orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (bin_location_id) REFERENCES bin_locations(id)
);
GO

-- ============================================================
-- STOCK MOVEMENTS
-- ============================================================
CREATE TABLE stock_movements (
    id              INT             PRIMARY KEY,
    product_id      INT             NOT NULL,
    from_bin_id     INT             NULL,
    to_bin_id       INT             NULL,
    quantity        INT             NOT NULL,
    movement_type   NVARCHAR(20)    NOT NULL CHECK (movement_type IN ('receive', 'pick', 'transfer', 'adjustment')),
    moved_at        DATETIME        NOT NULL,
    moved_by        INT             NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (from_bin_id) REFERENCES bin_locations(id),
    FOREIGN KEY (to_bin_id) REFERENCES bin_locations(id),
    FOREIGN KEY (moved_by) REFERENCES employees(id)
);
GO

-- IMPORTANT: Replace/adapt this starter schema to the assignment-provided erp_schema.sql
-- if one was supplied separately. Compose mounts this file for first-boot initialization.
CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.vendors (
    vendor_id VARCHAR(64) PRIMARY KEY,
    vendor_name VARCHAR(255) NOT NULL,
    currency CHAR(3),
    country VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS erp.purchase_orders (
    po_number VARCHAR(64) PRIMARY KEY,
    vendor_id VARCHAR(64) NOT NULL REFERENCES erp.vendors(vendor_id),
    currency CHAR(3) NOT NULL,
    po_date DATE,
    status VARCHAR(32)
);

CREATE TABLE IF NOT EXISTS erp.po_line_items (
    id BIGSERIAL PRIMARY KEY,
    po_number VARCHAR(64) NOT NULL REFERENCES erp.purchase_orders(po_number),
    line_number INTEGER NOT NULL,
    sku_code VARCHAR(64),
    description TEXT,
    quantity NUMERIC(12,3) NOT NULL,
    unit_price NUMERIC(14,4) NOT NULL,
    line_total NUMERIC(14,2) NOT NULL,
    UNIQUE (po_number, line_number)
);

CREATE TABLE IF NOT EXISTS erp.sku_master (
    sku_code VARCHAR(64) PRIMARY KEY,
    description TEXT,
    currency CHAR(3),
    default_unit_price NUMERIC(14,4)
);

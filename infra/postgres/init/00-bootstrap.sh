#!/bin/bash
set -euo pipefail

# PostgreSQL runs files in /docker-entrypoint-initdb.d only when the data directory
# is empty. The schema file is mounted at /bootstrap/erp_schema.sql by Compose.
psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set ON_ERROR_STOP=1 \
  --command "CREATE SCHEMA IF NOT EXISTS audit;"

if [[ ! -f /bootstrap/erp_schema.sql ]]; then
  echo "ERROR: /bootstrap/erp_schema.sql is missing" >&2
  exit 1
fi

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set ON_ERROR_STOP=1 \
  --file /bootstrap/erp_schema.sql

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set ON_ERROR_STOP=1 <<'SQL'
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.invoice_audit (
    invoice_id UUID PRIMARY KEY,
    file_path VARCHAR(512),
    file_checksum VARCHAR(64) UNIQUE,
    extraction_method VARCHAR(32),
    raw_extracted_text TEXT,
    translated_text TEXT,
    source_language VARCHAR(8),
    translation_confidence NUMERIC(4,3),
    invoice_number VARCHAR(64),
    vendor_name VARCHAR(255),
    po_number VARCHAR(64),
    invoice_date DATE,
    currency CHAR(3),
    total_amount NUMERIC(14,2),
    validation_status VARCHAR(32),
    recommendation VARCHAR(32),
    extracted_raw JSONB,
    thread_id VARCHAR(128),
    processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit.invoice_line_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES audit.invoice_audit(invoice_id),
    line_number INTEGER,
    item_code VARCHAR(64),
    description TEXT,
    quantity NUMERIC(12,3),
    unit_price NUMERIC(14,4),
    line_total NUMERIC(14,2)
);

CREATE TABLE IF NOT EXISTS audit.discrepancies (
    id BIGSERIAL PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES audit.invoice_audit(invoice_id),
    field_name VARCHAR(64),
    invoice_value TEXT,
    erp_value TEXT,
    deviation_pct NUMERIC(8,4),
    severity VARCHAR(16),
    detected_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit.human_feedback (
    id BIGSERIAL PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES audit.invoice_audit(invoice_id),
    field_name VARCHAR(64),
    original_value TEXT,
    corrected_value TEXT,
    corrected_by VARCHAR(128),
    corrected_at TIMESTAMPTZ DEFAULT now(),
    revalidated BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_invoice_audit_vendor ON audit.invoice_audit(vendor_name);
CREATE INDEX IF NOT EXISTS idx_invoice_audit_processed_at ON audit.invoice_audit(processed_at);
CREATE INDEX IF NOT EXISTS idx_discrepancies_invoice_id ON audit.discrepancies(invoice_id);
CREATE INDEX IF NOT EXISTS idx_feedback_invoice_id ON audit.human_feedback(invoice_id);
SQL

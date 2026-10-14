import os
from fastapi import FastAPI, HTTPException
import psycopg
from psycopg.rows import dict_row

app = FastAPI(title="Mock ERP API", version="1.0.0")
DATABASE_URL = os.environ["DATABASE_URL"]
DB_SCHEMA = os.getenv("DB_SCHEMA", "erp")


def fetch_one(query: str, params: tuple):
    # All ERP reads go through this HTTP service; the agent must not query erp tables.
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            row = cur.fetchone()
            return dict(row) if row else None


@app.get("/health")
def health():
    try:
        with psycopg.connect(DATABASE_URL) as conn:
            conn.execute("SELECT 1")
        return {"status": "ok", "service": "mock-erp"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail="database unavailable") from exc


@app.get("/po/{po_number}")
def get_purchase_order(po_number: str):
    # TODO: update SQL to match the actual supplied erp_schema.sql.
    row = fetch_one("SELECT * FROM erp.purchase_orders WHERE po_number = %s", (po_number,))
    if row is None:
        raise HTTPException(status_code=404, detail="purchase order not found")
    return row


@app.get("/vendor/{vendor_id}")
def get_vendor(vendor_id: str):
    row = fetch_one("SELECT * FROM erp.vendors WHERE vendor_id = %s", (vendor_id,))
    if row is None:
        raise HTTPException(status_code=404, detail="vendor not found")
    return row


@app.get("/sku/{sku_code}")
def get_sku(sku_code: str):
    row = fetch_one("SELECT * FROM erp.sku_master WHERE sku_code = %s", (sku_code,))
    if row is None:
        raise HTTPException(status_code=404, detail="SKU not found")
    return row

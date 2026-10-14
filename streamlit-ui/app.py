import os
import httpx
import streamlit as st
import psycopg
from psycopg.rows import dict_row

st.set_page_config(page_title="AI Invoice Auditor", layout="wide")
st.title("AI Invoice Auditor")
st.caption("Human review dashboard — starter scaffold")

DATABASE_URL = os.environ["DATABASE_URL"]
AGENT_BASE_URL = os.getenv("AGENT_BASE_URL", "http://agent:8000")

st.info(
    "Wire this page to audit.invoice_audit, audit.discrepancies and "
    "audit.human_feedback. Corrections should INSERT into human_feedback; "
    "never overwrite the original extracted value."
)

if st.button("Check agent health"):
    try:
        response = httpx.get(f"{AGENT_BASE_URL}/health", timeout=5)
        st.write(response.json())
    except httpx.HTTPError as exc:
        st.error(f"Agent is not reachable: {exc}")

if st.button("Check PostgreSQL connection"):
    try:
        with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
            row = conn.execute("SELECT current_database() AS database").fetchone()
        st.success(f"Connected to database: {row['database']}")
    except Exception as exc:
        st.error(f"Database connection failed: {exc}")

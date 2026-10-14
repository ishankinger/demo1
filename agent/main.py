from fastapi import FastAPI

app = FastAPI(title="AI Invoice Auditor Agent", version="1.0.0")


@app.get("/health")
def health():
    # Extend this with dependency checks if desired; Compose separately gates startup
    # on infrastructure health and the ERP API health endpoint.
    return {"status": "ok", "service": "agent"}


@app.post("/invoices/revalidate/{invoice_id}")
def revalidate_invoice(invoice_id: str):
    # TODO: call the LangGraph workflow and persist correction/revalidation events.
    return {"status": "not_implemented", "invoice_id": invoice_id}

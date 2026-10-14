# AI Invoice Auditor — container scaffold

This scaffold covers the container and service boundaries in the assignment. It is **not** the complete invoice-processing implementation: the LangGraph nodes, extraction/translation/validation/RAG workflow, seeded ERP data, and full Streamlit review UI still need to be implemented.

## Structure

```text
.
├── compose.yaml
├── .env.example
├── agent/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── requirements.txt
│   ├── main.py
│   ├── graph/                 # add LangGraph graph and nodes here
│   ├── services/              # extraction, translation, ERP client, reports
│   ├── rag/                   # chunking, indexing, retrieval, reflection
│   └── config/                # agent-specific config if needed
├── mock-erp/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── requirements.txt
│   ├── main.py
│   └── erp_schema.sql
├── streamlit-ui/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── requirements.txt
│   └── app.py
├── infra/postgres/init/        # first-boot SQL/bootstrap
├── config/rules.yaml
└── data/
    ├── incoming/               # mounted invoice input directory
    └── reports/                # generated JSON/HTML reports
```

## Configure and start

1. Install Docker Engine/Desktop with Compose v2.
2. Copy `.env.example` to `.env` and set a strong `POSTGRES_PASSWORD`, valid AWS Bedrock configuration, and model IDs.
3. Check `mock-erp/erp_schema.sql` against the exact ERP schema supplied with your course materials. Add seed data separately if required.
4. Start the stack:

   ```bash
   docker compose up --build -d
   docker compose ps
   docker compose logs -f agent
   ```

5. Open Streamlit at `http://localhost:8501`, agent health at `http://localhost:8000/health`, and mock ERP at `http://localhost:8001/health`.

## Important architecture rules

- From containers, use service DNS names and **container ports**: `postgres:5432`, `qdrant:6333`, `redis:6379`, `mock-erp:8000`, and `agent:8000`.
- Only `mock-erp` reads the `erp` schema. The agent validates against ERP through HTTP.
- The agent owns application writes to `audit`; the UI reads audit records and asks the agent to revalidate. Human corrections should be appended to `audit.human_feedback`, never overwrite original extraction.
- PostgreSQL and Qdrant use named volumes. `docker compose down` retains them; `docker compose down -v` deletes them.
- Incoming invoices and report files are bind-mounted from `./data`, so they remain on the host across container recreation.
- Redis is disposable cache and intentionally has no persistent volume.
- Compose health checks and `depends_on: condition: service_healthy` gate application startup.
- `infra/postgres/init/00-bootstrap.sh` runs only when PostgreSQL initializes an empty data directory. Changing SQL after the volume has been created will not automatically re-run initialization. For a disposable development database, `docker compose down -v` and restart; do not do this when you need to retain data.
- `.env` is not copied into images. Do not commit it or pass secrets as Docker build arguments.

## Persistence checks

```bash
# Stop/remove containers but keep named volumes
docker compose down
docker compose up --build -d

# Destructive: removes PostgreSQL and Qdrant named volumes too
docker compose down -v
docker compose up --build -d
```

## Verify images contain no credentials

```bash
docker history ai-invoice-auditor-agent:1.0 --no-trunc
docker history ai-invoice-auditor-mock-erp:1.0 --no-trunc
docker history ai-invoice-auditor-streamlit-ui:1.0 --no-trunc
```

## Before submission

- Replace starter `mock-erp/erp_schema.sql` with the exact schema from the assignment package if provided separately.
- Seed representative vendors, POs, PO line items, and SKUs.
- Implement the actual invoice monitor and checksum deduplication, PDF/DOCX/OCR extraction, translation and Redis caching, validation agents, discrepancy/report persistence, Qdrant indexing and RAG reflection/retry loop, and human correction flow.
- Add tests and verify all six checks in the assignment.

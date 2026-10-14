FROM python:3.11.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install only required OCR/PDF system packages. Add other Tesseract language
# packs here if the invoice dataset contains languages beyond English/Spanish/German.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       tesseract-ocr \
       tesseract-ocr-eng \
       tesseract-ocr-spa \
       tesseract-ocr-deu \
       poppler-utils \
       libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Dependency layer changes less often than application source.
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /data/incoming /data/reports \
    && chown -R appuser:appuser /app /data

COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

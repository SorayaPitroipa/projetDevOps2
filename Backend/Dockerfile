FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

COPY requirements.txt ./
RUN python -m pip install --upgrade pip && \
    python -m pip install -r requirements.txt

COPY . .

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
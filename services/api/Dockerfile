FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Certs montados via Docker volume en /certs
CMD ["uvicorn", "main:app", \
     "--host", "0.0.0.0", \
     "--port", "8443", \
     "--ssl-keyfile", "/certs/server/server.key", \
     "--ssl-certfile", "/certs/server/server.crt", \
     "--ssl-ca-certs", "/certs/ca/ca.crt", \
     "--ssl-cert-reqs", "2"]

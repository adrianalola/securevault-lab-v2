#!/bin/bash
set -e

CERTS_DIR="$(dirname "$0")/../certs"
cd "$CERTS_DIR"

echo "==> Generando Certificate Authority..."
openssl genrsa -out ca/ca.key 4096
openssl req -new -x509 -days 365 -key ca/ca.key -out ca/ca.crt \
    -subj "/C=SK/ST=Kosice/O=SecureVault Lab/CN=SecureVault CA"

echo "==> Generando certificado del servidor..."
openssl genrsa -out server/server.key 2048
openssl req -new -key server/server.key -out server/server.csr \
    -subj "/C=SK/ST=Kosice/O=SecureVault Lab/CN=api-service"
openssl x509 -req -days 365 \
    -in server/server.csr \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
    -out server/server.crt \
    -extfile <(printf "subjectAltName=DNS:api-service,DNS:localhost,IP:127.0.0.1")

echo "==> Generando certificado del cliente..."
openssl genrsa -out client/client.key 2048
openssl req -new -key client/client.key -out client/client.csr \
    -subj "/C=SK/ST=Kosice/O=SecureVault Lab/CN=securevault-client"
openssl x509 -req -days 365 \
    -in client/client.csr \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
    -out client/client.crt

echo "==> Certificados generados:"
ls -la ca/ server/ client/
echo "==> Verificando cadena de confianza..."
openssl verify -CAfile ca/ca.crt server/server.crt
openssl verify -CAfile ca/ca.crt client/client.crt
echo "==> Todo OK!"

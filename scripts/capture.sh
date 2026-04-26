#!/bin/sh
# Captura tráfico en la interfaz de la red DMZ
# Filtra solo el puerto 8443 (API)

echo "==> Iniciando captura en puerto 8443..."
echo "==> Presiona Ctrl+C para detener"
echo ""

tshark -i any \
    -f "tcp port 8443" \
    -Y "tls or http" \
    -T fields \
    -e frame.number \
    -e frame.time_relative \
    -e ip.src \
    -e ip.dst \
    -e tls.record.content_type \
    -e tls.handshake.type \
    -e http.request.method \
    -e http.request.uri \
    -E header=y \
    -E separator="|" \
    2>/dev/null

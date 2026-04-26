#!/usr/bin/env python3
"""
SecureVault Client
Flujo: SSH tunnel -> bastion -> mTLS -> API -> PostgreSQL
"""

import subprocess
import time
import ssl
import urllib.request
import urllib.error
import json
import sys
import os

# ── Configuración ─────────────────────────────────────────
BASTION_HOST     = "localhost"
BASTION_PORT     = 2222
BASTION_USER     = "bastionuser"
SSH_KEY          = os.path.expanduser("~/.ssh/securevault_bastion")
LOCAL_PORT       = 9443
REMOTE_HOST      = "securevault_api"
REMOTE_PORT      = 8443

CERTS_DIR        = os.path.join(os.path.dirname(__file__), "..", "certs")
CA_CERT          = os.path.join(CERTS_DIR, "ca", "ca.crt")
CLIENT_CERT      = os.path.join(CERTS_DIR, "client", "client.crt")
CLIENT_KEY       = os.path.join(CERTS_DIR, "client", "client.key")

def print_step(msg):
    print(f"\n{'='*50}")
    print(f"  {msg}")
    print(f"{'='*50}")

def open_ssh_tunnel():
    """Abre un túnel SSH: localhost:9443 -> bastión -> api:8443"""
    print_step("1. Abriendo túnel SSH...")
    print(f"   {BASTION_USER}@{BASTION_HOST}:{BASTION_PORT}")
    print(f"   Tunel: localhost:{LOCAL_PORT} -> {REMOTE_HOST}:{REMOTE_PORT}")

    cmd = [
        "ssh",
        "-i", SSH_KEY,
        "-p", str(BASTION_PORT),
        "-L", f"{LOCAL_PORT}:{REMOTE_HOST}:{REMOTE_PORT}",
        "-N",                        # No ejecuta comando remoto
        "-f",                        # Va a background
        "-o", "StrictHostKeyChecking=no",
        "-o", "ExitOnForwardFailure=yes",
        f"{BASTION_USER}@{BASTION_HOST}"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"   ERROR: {result.stderr}")
        sys.exit(1)

    print("   Tunel SSH abierto.")
    time.sleep(1)

def make_mtls_request(endpoint):
    """Hace una request con mTLS a través del túnel SSH"""
    url = f"https://localhost:{LOCAL_PORT}{endpoint}"
    print(f"\n   GET {url}")

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ctx.load_verify_locations(CA_CERT)
    ctx.load_cert_chain(CLIENT_CERT, CLIENT_KEY)

    try:
        req = urllib.request.urlopen(url, context=ctx)
        data = json.loads(req.read().decode())
        print(f"   Respuesta: {json.dumps(data, indent=4, ensure_ascii=False)}")
        return data
    except urllib.error.URLError as e:
        print(f"   ERROR: {e}")
        return None

def close_tunnel():
    """Cierra el túnel SSH"""
    print_step("4. Cerrando túnel SSH...")
    subprocess.run(
        ["pkill", "-f", f"ssh.*{LOCAL_PORT}:{REMOTE_HOST}"],
        capture_output=True
    )
    print("   Tunel cerrado.")

def main():
    print("\n" + "="*50)
    print("  SecureVault Client")
    print("  SSH Tunnel + mTLS Demo")
    print("="*50)

    # 1. Abre el túnel
    open_ssh_tunnel()

    # 2. Health check
    print_step("2. Health check via mTLS...")
    make_mtls_request("/health")

    # 3. Datos secretos
    print_step("3. Accediendo a datos secretos...")
    make_mtls_request("/secret")

    # 4. Base de datos
    print_step("3. Consultando base de datos...")
    make_mtls_request("/db-test")

    # 5. Cierra el túnel
    close_tunnel()

    print("\n✓ Flujo completo SSH tunnel + mTLS completado.\n")

if __name__ == "__main__":
    main()

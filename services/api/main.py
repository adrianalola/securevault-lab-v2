from fastapi import FastAPI, Request, HTTPException
import ssl
import os

app = FastAPI(title="SecureVault API")

@app.get("/health")
async def health():
    return {"status": "ok", "mtls": "enabled"}

@app.get("/secret")
async def get_secret(request: Request):
    # mTLS ya fue validado por uvicorn antes de llegar aquí
    # Extraemos el CN del certificado del cliente para logging
    client_cert = request.scope.get("ssl_object")
    return {
        "message": "Acceso concedido via mTLS",
        "data": "TOP SECRET: la infraestructura es hermosa"
    }

@app.get("/db-test")
async def db_test():
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "securevault_db"),
            port=5432,
            database=os.getenv("DB_NAME", "securevault"),
            user=os.getenv("DB_USER", "vaultuser"),
            password=os.getenv("DB_PASS", "vaultpass")
        )
        cur = conn.cursor()
        cur.execute("SELECT name, classification FROM secrets LIMIT 3;")
        rows = cur.fetchall()
        conn.close()
        return {"secrets": [{"name": r[0], "classification": r[1]} for r in rows]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

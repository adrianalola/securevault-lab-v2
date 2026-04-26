CREATE TABLE secrets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    value TEXT NOT NULL,
    classification VARCHAR(50) DEFAULT 'confidential',
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO secrets (name, value, classification) VALUES
    ('db_password', 'sup3r_s3cr3t_pw', 'top-secret'),
    ('api_key', 'sk-prod-abc123xyz', 'confidential'),
    ('encryption_key', 'aes256-key-material', 'top-secret');

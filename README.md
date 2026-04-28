# SecureVault Lab

A hands-on Cloud Security lab demonstrating defense in depth principles using Docker, Terraform, and Python with an equivalent Azure architecture in code.

## Security Concepts Demonstrated

| Concept | Implementation |
|---|---|
| Network segmentation | Three isolated Docker networks (public / DMZ / private) |
| Zero trust access | No direct access to private zone everything through bastion |
| SSH hardening | Key only auth, no root, no password, ED25519 |
| PKI and certificates | Self signed CA, server and client certs with OpenSSL |
| Mutual TLS (mTLS) | FastAPI rejects any request without valid client certificate |
| SSH tunneling | Port forwarding through bastion to reach private API |
| Packet capture | TShark capturing TLS 1.3 handshake and encrypted payloads |
| Infrastructure as Code | Full environment provisioned with Terraform |
| Least privilege | DB has no exposed ports  only reachable from private network |

## Architecture

    [Client] --> SSH tunnel --> [Bastion/DMZ] --> mTLS --> [API/Private] --> [PostgreSQL/Private]
                                      |
                               [TShark capture]

### Security Zones

- **Public zone** — untrusted, client entry point
- **DMZ** — bastion host and TShark packet capture sidecar
- **Private zone** — API (FastAPI + mTLS) and PostgreSQL, no external ports exposed

## Project Structure

    securevault-lab/
    ├── terraform/          # Local Docker infrastructure (IaC)
    ├── terraform-azure/    # Equivalent Azure architecture (IaC)
    ├── services/
    │   ├── bastion/        # OpenSSH hardened container
    │   ├── api/            # FastAPI with mTLS enforcement
    │   └── db/             # PostgreSQL schema and seed data
    ├── certs/              # Generated certificates (gitignored)
    ├── scripts/
    │   ├── gen_certs.sh    # CA + mTLS certificate generation
    │   └── capture.sh      # TShark packet capture
    └── client/
        └── request.py      # End-to-end client: SSH tunnel + mTLS

## Prerequisites

- Docker
- Terraform
- Python 3.11+
- OpenSSL

## Quick Start

1. Generate certificates

    bash scripts/gen_certs.sh

2. Provision infrastructure

    cd terraform && terraform init && terraform apply

3. Run end-to-end demo

    python3 client/request.py

4. Capture packets

    docker exec -d securevault_api tshark -i any -w /tmp/capture.pcap
    docker exec securevault_api tshark -r /tmp/capture.pcap 2>/dev/null

## Azure Equivalent

The terraform-azure/ directory contains the equivalent architecture for Azure:

| Local Docker | Azure |
|---|---|
| Docker network private with internal=true | VNet private subnet + NSG deny-all |
| Bastion container with OpenSSH | Azure Bastion managed service |
| TShark packet capture | Azure Network Watcher + Packet Capture |
| mTLS between containers | Application Gateway with mutual TLS |
| PostgreSQL no exposed ports | Azure Database for PostgreSQL + Private Endpoint |
| Three isolated networks | VNet with subnets + NSGs per zone |

## AZ-500 Relevance

This lab directly reinforces the following AZ-500 domains:

- **Secure networking** — VNet segmentation, NSGs, Private Endpoints
- **Identity and access** — certificate-based mutual authentication
- **Security monitoring** — packet capture, traffic inspection
- **Infrastructure security** — bastion host pattern, least privilege

## Author

Adriana — DevSecOps Engineer in training
AWS Solutions Architect Associate | Google Cybersecurity Certificate | AZ-500 in progress via TUV Rheinland

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# ── Zona pública ──────────────────────────────────────────
resource "docker_network" "public" {
  name   = "securevault_public"
  driver = "bridge"

  ipam_config {
    subnet  = var.public_subnet
    gateway = "10.0.1.1"
  }
}

# ── DMZ ───────────────────────────────────────────────────
resource "docker_network" "dmz" {
  name   = "securevault_dmz"
  driver = "bridge"

  ipam_config {
    subnet  = var.dmz_subnet
    gateway = "10.0.2.1"
  }
}

# ── Zona privada ──────────────────────────────────────────
# internal = true = Docker no crea ruta al exterior. Aislada.
resource "docker_network" "private" {
  name     = "securevault_private"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet  = var.private_subnet
    gateway = "10.0.3.1"
  }
}

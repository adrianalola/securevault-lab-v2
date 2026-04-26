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

# ── Imagen del bastión ────────────────────────────────────
resource "docker_image" "bastion" {
  name = "securevault-bastion:latest"
  build {
    context = "../services/bastion"
  }
}

# ── Contenedor bastión ────────────────────────────────────
resource "docker_container" "bastion" {
  name  = "securevault_bastion"
  image = docker_image.bastion.image_id

  # Expone SSH al host en puerto 2222
  ports {
    internal = 22
    external = 2222
  }

  # Una pata en pública, otra en privada
  networks_advanced {
    name = docker_network.public.name
  }

  networks_advanced {
    name = docker_network.dmz.name
  }

  networks_advanced {
    name = docker_network.private.name
  }

  restart = "unless-stopped"
}

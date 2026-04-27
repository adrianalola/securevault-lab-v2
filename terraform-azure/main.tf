terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ── Resource Group ────────────────────────────────────────
resource "azurerm_resource_group" "securevault" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── Virtual Network ───────────────────────────────────────
# Equivalente a las tres redes Docker
resource "azurerm_virtual_network" "securevault" {
  name                = "vnet-securevault"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# ── Subnet pública ────────────────────────────────────────
resource "azurerm_subnet" "public" {
  name                 = "snet-public"
  resource_group_name  = azurerm_resource_group.securevault.name
  virtual_network_name = azurerm_virtual_network.securevault.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ── Subnet DMZ (Azure Bastion requiere este nombre exacto)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.securevault.name
  virtual_network_name = azurerm_virtual_network.securevault.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ── Subnet privada ────────────────────────────────────────
resource "azurerm_subnet" "private" {
  name                 = "snet-private"
  resource_group_name  = azurerm_resource_group.securevault.name
  virtual_network_name = azurerm_virtual_network.securevault.name
  address_prefixes     = ["10.0.3.0/24"]
}

# ── NSG zona pública ──────────────────────────────────────
# Equivalente a las reglas de red Docker en zona pública
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ── NSG zona privada ──────────────────────────────────────
# Solo permite tráfico desde la DMZ — equivalente a internal=true
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location

  security_rule {
    name                       = "allow-dmz-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-dmz-postgres"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ── Asociar NSGs a subnets ────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

# ── Azure Bastion ─────────────────────────────────────────
# Equivalente al contenedor bastión con SSH
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "securevault" {
  name                = "bastion-securevault"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

# ── Private Endpoint para PostgreSQL ─────────────────────
# Equivalente a PostgreSQL sin puerto expuesto
resource "azurerm_postgresql_flexible_server" "securevault" {
  name                   = "psql-securevault"
  resource_group_name    = azurerm_resource_group.securevault.name
  location               = var.location
  version                = "15"
  administrator_login    = "vaultuser"
  administrator_password = var.db_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768

  # Sin acceso público — solo via Private Endpoint
  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_private_endpoint" "postgres" {
  name                = "pe-postgres"
  resource_group_name = azurerm_resource_group.securevault.name
  location            = var.location
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "psc-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.securevault.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

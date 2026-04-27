output "bastion_public_ip" {
  description = "IP publica del Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = azurerm_virtual_network.securevault.id
}

output "private_subnet_id" {
  description = "ID de la subnet privada"
  value       = azurerm_subnet.private.id
}

output "postgres_fqdn" {
  description = "FQDN del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.securevault.fqdn
}

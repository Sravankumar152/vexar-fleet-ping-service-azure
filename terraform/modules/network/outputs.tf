output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "Subnet ID for AKS nodes."
  value       = azurerm_subnet.aks.id
}

output "postgres_subnet_id" {
  description = "Delegated subnet ID for PostgreSQL Flexible Server."
  value       = azurerm_subnet.postgres.id
}

output "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints."
  value       = azurerm_subnet.private_endpoints.id
}

output "postgres_private_dns_zone_id" {
  description = "Private DNS zone ID for PostgreSQL."
  value       = azurerm_private_dns_zone.postgres.id
}

output "keyvault_private_dns_zone_id" {
  description = "Private DNS zone ID for Key Vault (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_dns_zone.keyvault[0].id : null
}

output "acr_private_dns_zone_id" {
  description = "Private DNS zone ID for ACR (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_dns_zone.acr[0].id : null
}

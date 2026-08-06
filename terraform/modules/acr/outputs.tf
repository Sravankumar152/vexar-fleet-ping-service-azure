output "id" {
  description = "ACR resource ID."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "ACR login server (e.g. vexaracr.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "name" {
  value = azurerm_container_registry.this.name
}

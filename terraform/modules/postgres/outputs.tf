output "server_id" {
  value = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "Fully-qualified domain name of the server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.app.name
}

output "connection_string_secret_name" {
  description = "Key Vault secret name holding the pooled connection string."
  value       = azurerm_key_vault_secret.db_connection_string.name
}

output "password_secret_name" {
  value = azurerm_key_vault_secret.db_password.name
}

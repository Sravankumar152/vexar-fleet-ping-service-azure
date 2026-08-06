output "client_id" {
  description = "Client ID of the app managed identity (annotate the K8s SA with this)."
  value       = azurerm_user_assigned_identity.app.client_id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "identity_id" {
  value = azurerm_user_assigned_identity.app.id
}

output "service_account_namespace" {
  value = var.service_account_namespace
}

output "service_account_name" {
  value = var.service_account_name
}

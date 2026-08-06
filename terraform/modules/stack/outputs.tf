output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "key_vault_uri" {
  value = module.keyvault.uri
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "app_identity_client_id" {
  description = "Annotate the Kubernetes ServiceAccount with this client ID."
  value       = module.identity.client_id
}

output "db_connection_string_secret_name" {
  value = module.postgres.connection_string_secret_name
}

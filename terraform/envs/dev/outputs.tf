output "resource_group_name" {
  value = module.stack.resource_group_name
}

output "acr_login_server" {
  value = module.stack.acr_login_server
}

output "aks_cluster_name" {
  value = module.stack.aks_cluster_name
}

output "key_vault_uri" {
  value = module.stack.key_vault_uri
}

output "postgres_fqdn" {
  value = module.stack.postgres_fqdn
}

output "app_identity_client_id" {
  description = "Set this as the workload-identity client ID on the K8s ServiceAccount."
  value       = module.stack.app_identity_client_id
}

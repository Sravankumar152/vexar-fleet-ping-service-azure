# -----------------------------------------------------------------------------
# Composition root
# Wires every building block into one environment. The dev/ and prod/ roots
# only pass sizing + toggles, so a new environment is a copy-paste + tfvars.
# Dependency order: RG -> network -> acr/keyvault -> postgres -> monitoring
#                   -> aks -> app identity.
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = var.tags
}

module "network" {
  source                   = "../../modules/network"
  name_prefix              = var.name_prefix
  location                 = var.location
  resource_group_name      = azurerm_resource_group.this.name
  vnet_cidr                = var.vnet_cidr
  aks_subnet_cidr          = var.aks_subnet_cidr
  postgres_subnet_cidr     = var.postgres_subnet_cidr
  pe_subnet_cidr           = var.pe_subnet_cidr
  enable_private_endpoints = var.enable_private_endpoints
  tags                     = var.tags
}

module "acr" {
  source                        = "../../modules/acr"
  acr_name                      = var.acr_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  sku                           = var.acr_sku
  public_network_access_enabled = !var.enable_private_endpoints
  enable_private_endpoint       = var.enable_private_endpoints
  private_endpoint_subnet_id    = module.network.private_endpoint_subnet_id
  private_dns_zone_id           = module.network.acr_private_dns_zone_id
  tags                          = var.tags
}

module "keyvault" {
  source                        = "../../modules/keyvault"
  key_vault_name                = var.key_vault_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  public_network_access_enabled = !var.enable_private_endpoints
  allowed_ip_rules              = var.keyvault_allowed_ip_rules
  purge_protection_enabled      = var.enable_private_endpoints
  enable_private_endpoint       = var.enable_private_endpoints
  private_endpoint_subnet_id    = module.network.private_endpoint_subnet_id
  private_dns_zone_id           = module.network.keyvault_private_dns_zone_id
  tags                          = var.tags
}

# JWT signing key: generated here, stored only in Key Vault (never in git).
resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "azurerm_key_vault_secret" "jwt" {
  name         = "jwt-secret"
  value        = random_password.jwt.result
  key_vault_id = module.keyvault.id
  content_type = "text/plain"
  tags         = var.tags

  depends_on = [module.keyvault]
}

module "postgres" {
  source                       = "../../modules/postgres"
  server_name                  = var.postgres_server_name
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  postgres_version             = var.postgres_version
  sku_name                     = var.postgres_sku_name
  storage_mb                   = var.postgres_storage_mb
  database_name                = var.database_name
  delegated_subnet_id          = module.network.postgres_subnet_id
  private_dns_zone_id          = module.network.postgres_private_dns_zone_id
  key_vault_id                 = module.keyvault.id
  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup
  high_availability_enabled    = var.postgres_high_availability
  tags                         = var.tags
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  name_prefix             = var.name_prefix
  resource_group_name     = azurerm_resource_group.this.name
  location                = var.location
  log_retention_days      = var.log_retention_days
  daily_quota_gb          = var.log_daily_quota_gb
  alert_emails            = var.alert_emails
  postgres_server_id      = module.postgres.server_id
  action_group_short_name = var.action_group_short_name
  tags                    = var.tags
}

module "aks" {
  source                     = "../../modules/aks"
  name_prefix                = var.name_prefix
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  kubernetes_version         = var.kubernetes_version
  sku_tier                   = var.aks_sku_tier
  aks_subnet_id              = module.network.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id
  system_node_vm_size        = var.aks_system_node_vm_size
  system_node_min_count      = var.aks_system_node_min_count
  system_node_max_count      = var.aks_system_node_max_count
  dedicated_system_pool      = var.aks_dedicated_system_pool
  enable_spot_pool           = var.aks_enable_spot_pool
  private_cluster_enabled    = var.aks_private_cluster
  local_account_disabled     = var.aks_local_account_disabled
  admin_group_object_ids     = var.aks_admin_group_object_ids
  tags                       = var.tags
}

module "identity" {
  source                    = "../../modules/identity"
  name_prefix               = var.name_prefix
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  oidc_issuer_url           = module.aks.oidc_issuer_url
  key_vault_id              = module.keyvault.id
  service_account_namespace = var.service_account_namespace
  service_account_name      = var.service_account_name
  tags                      = var.tags
}

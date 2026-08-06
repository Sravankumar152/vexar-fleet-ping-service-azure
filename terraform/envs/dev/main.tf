# -----------------------------------------------------------------------------
# DEV environment
# Cheapest viable footprint: Burstable DB, Free AKS tier, single node to start,
# public (firewalled) Key Vault/ACR, no HA. Good enough to validate the stack.
# -----------------------------------------------------------------------------

locals {
  env  = "dev"
  tags = {
    application = "fleet-ping-service"
    environment = "dev"
    managed_by  = "terraform"
    owner       = "platform-team"
  }
}

module "stack" {
  source = "../../modules/stack"

  name_prefix = "vexar-fleet-${local.env}"
  location    = var.location
  tags        = local.tags

  # Cost mode: keep KV/ACR public-but-firewalled, no private endpoints.
  enable_private_endpoints = false

  # Unique resource names.
  acr_name             = var.acr_name
  key_vault_name       = var.key_vault_name
  postgres_server_name = var.postgres_server_name

  # PostgreSQL — small burstable, 7-day PITR, single AZ.
  postgres_sku_name              = "B_Standard_B1ms"
  postgres_storage_mb            = 32768
  postgres_backup_retention_days = 7
  postgres_geo_redundant_backup  = false
  postgres_high_availability     = false

  # AKS — Free tier, one small autoscaling node to start.
  aks_sku_tier              = "Free"
  aks_system_node_vm_size   = "Standard_B2s"
  aks_system_node_min_count = 1
  aks_system_node_max_count = 2
  aks_enable_spot_pool      = false
  aks_private_cluster       = false
  aks_local_account_disabled = false
  aks_admin_group_object_ids = var.aks_admin_group_object_ids

  # Monitoring — modest retention + daily cap to control spend.
  log_retention_days = 30
  log_daily_quota_gb = 1
  alert_emails       = var.alert_emails
}

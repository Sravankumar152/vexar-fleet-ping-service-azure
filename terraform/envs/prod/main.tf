# -----------------------------------------------------------------------------
# PROD environment
# Reliability first, cost second: zone-redundant HA database, geo-redundant
# backups, private endpoints for KV/ACR, private AKS API server, AAD-only
# cluster access, and a Spot pool for cheap burst headroom.
# -----------------------------------------------------------------------------

locals {
  env  = "prod"
  tags = {
    application = "fleet-ping-service"
    environment = "prod"
    managed_by  = "terraform"
    owner       = "platform-team"
  }
}

module "stack" {
  source = "../../modules/stack"

  name_prefix = "vexar-fleet-${local.env}"
  location    = var.location
  tags        = local.tags

  # Lock the data plane down with private networking.
  enable_private_endpoints = true

  acr_name             = var.acr_name
  acr_sku              = "Premium" # required for private endpoint + geo-replication
  key_vault_name       = var.key_vault_name
  postgres_server_name = var.postgres_server_name

  # PostgreSQL — general-purpose, HA, geo-redundant backups, 35-day PITR.
  postgres_sku_name              = "GP_Standard_D2ds_v5"
  postgres_storage_mb            = 131072
  postgres_backup_retention_days = 35
  postgres_geo_redundant_backup  = true
  postgres_high_availability     = true

  # AKS — Standard tier (SLA), autoscaling general pool + optional Spot burst
  # pool, private API server, AAD-only access. The system pool also runs the
  # app: a dedicated (tainted) system pool is deferred until multi-service
  # scale justifies the extra node cost — see report.
  aks_sku_tier               = "Standard"
  aks_system_node_vm_size    = "Standard_D2s_v5"
  aks_system_node_min_count  = 2
  aks_system_node_max_count  = 5
  aks_dedicated_system_pool  = false
  aks_enable_spot_pool       = true
  aks_private_cluster        = true
  aks_local_account_disabled = true
  aks_admin_group_object_ids = var.aks_admin_group_object_ids

  # Monitoring — longer retention, no daily cap (don't drop prod telemetry).
  log_retention_days = 90
  log_daily_quota_gb = -1
  alert_emails       = var.alert_emails
}

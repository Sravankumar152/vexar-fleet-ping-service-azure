# ---- Global ----
variable "name_prefix" {
  description = "Prefix for all resource names, e.g. vexar-fleet-dev."
  type        = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_private_endpoints" {
  description = "Use private endpoints + private DNS for KV/ACR (prod)."
  type        = bool
  default     = false
}

# ---- Network ----
variable "vnet_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "aks_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}
variable "postgres_subnet_cidr" {
  type    = string
  default = "10.20.2.0/24"
}
variable "pe_subnet_cidr" {
  type    = string
  default = "10.20.3.0/24"
}

# ---- ACR ----
variable "acr_name" {
  type = string
}
variable "acr_sku" {
  type    = string
  default = "Basic"
}

# ---- Key Vault ----
variable "key_vault_name" {
  type = string
}
variable "keyvault_allowed_ip_rules" {
  type    = list(string)
  default = []
}

# ---- PostgreSQL ----
variable "postgres_server_name" {
  type = string
}
variable "postgres_version" {
  type    = string
  default = "16"
}
variable "postgres_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}
variable "postgres_storage_mb" {
  type    = number
  default = 32768
}
variable "database_name" {
  type    = string
  default = "vexar_fleet"
}
variable "postgres_backup_retention_days" {
  type    = number
  default = 7
}
variable "postgres_geo_redundant_backup" {
  type    = bool
  default = false
}
variable "postgres_high_availability" {
  type    = bool
  default = false
}

# ---- Monitoring ----
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "log_daily_quota_gb" {
  type    = number
  default = 1
}
variable "alert_emails" {
  type    = list(string)
  default = []
}
variable "action_group_short_name" {
  type    = string
  default = "fleetalert"
}

# ---- AKS ----
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}
variable "aks_sku_tier" {
  type    = string
  default = "Free"
}
variable "aks_system_node_vm_size" {
  type    = string
  default = "Standard_B2s"
}
variable "aks_system_node_min_count" {
  type    = number
  default = 1
}
variable "aks_system_node_max_count" {
  type    = number
  default = 3
}
variable "aks_dedicated_system_pool" {
  type    = bool
  default = false
}
variable "aks_enable_spot_pool" {
  type    = bool
  default = false
}
variable "aks_private_cluster" {
  type    = bool
  default = false
}
variable "aks_local_account_disabled" {
  type    = bool
  default = false
}
variable "aks_admin_group_object_ids" {
  type    = list(string)
  default = []
}

# ---- App workload identity ----
variable "service_account_namespace" {
  type    = string
  default = "fleet"
}
variable "service_account_name" {
  type    = string
  default = "fleet-ping"
}

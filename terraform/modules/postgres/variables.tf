variable "server_name" {
  description = "Globally-unique PostgreSQL Flexible Server name."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "postgres_version" {
  description = "Major PostgreSQL version."
  type        = string
  default     = "16"
}

variable "administrator_login" {
  description = "Admin/provisioning login. The app uses a separate least-privilege role."
  type        = string
  default     = "vexaradmin"
}

variable "sku_name" {
  description = "Compute SKU, e.g. B_Standard_B1ms (dev) or GP_Standard_D2ds_v5 (prod)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage in MB (min 32768)."
  type        = number
  default     = 32768
}

variable "database_name" {
  type    = string
  default = "vexar_fleet"
}

variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "key_vault_id" {
  description = "Key Vault to store generated credentials in."
  type        = string
}

variable "backup_retention_days" {
  description = "Automated backup retention (7-35). Enables point-in-time recovery."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Geo-redundant backups (prod)."
  type        = bool
  default     = false
}

variable "high_availability_enabled" {
  description = "Zone-redundant HA (prod). Roughly doubles compute cost."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

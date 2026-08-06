variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_retention_days" {
  description = "Log Analytics retention."
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB (-1 for unlimited)."
  type        = number
  default     = 1
}

variable "action_group_short_name" {
  description = "<=12 char short name for the action group."
  type        = string
  default     = "fleetalert"
}

variable "alert_emails" {
  description = "Email addresses to notify on alerts."
  type        = list(string)
  default     = []
}

variable "postgres_server_id" {
  description = "PostgreSQL Flexible Server ID to attach DB alerts to."
  type        = string
}

variable "pg_connection_alert_threshold" {
  description = "active_connections threshold for the connection alert."
  type        = number
  default     = 80
}

variable "tags" {
  type    = map(string)
  default = {}
}

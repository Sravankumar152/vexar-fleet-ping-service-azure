variable "subscription_id" {
  description = "Azure subscription ID (or set ARM_SUBSCRIPTION_ID)."
  type        = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "acr_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "postgres_server_name" {
  type = string
}

variable "alert_emails" {
  description = "Emails to notify on alerts."
  type        = list(string)
  default     = []
}

variable "aks_admin_group_object_ids" {
  description = "AAD group object IDs granted cluster-admin. Required in prod."
  type        = list(string)
}

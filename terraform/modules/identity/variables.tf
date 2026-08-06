variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault the app identity may read secrets from."
  type        = string
}

variable "service_account_namespace" {
  type    = string
  default = "fleet"
}

variable "service_account_name" {
  type    = string
  default = "fleet-ping"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_vault_name" {
  description = "Globally-unique Key Vault name (3-24 chars)."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "public_network_access_enabled" {
  description = "Allow public network access (dev). Prod should use private endpoints."
  type        = bool
  default     = true
}

variable "allowed_ip_rules" {
  description = "CIDRs allowed through the vault firewall when public access is on."
  type        = list(string)
  default     = []
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (recommended for prod)."
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "deployer_principal_id" {
  description = "Principal ID granted Secrets Officer to seed secrets. Defaults to the caller."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

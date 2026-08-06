variable "name_prefix" {
  description = "Short prefix used to name resources, e.g. 'vexar-fleet-dev'."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create network resources in."
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR for AKS nodes (Azure CNI Overlay keeps pod IPs separate)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "postgres_subnet_cidr" {
  description = "Delegated subnet CIDR for PostgreSQL Flexible Server."
  type        = string
  default     = "10.20.2.0/24"
}

variable "pe_subnet_cidr" {
  description = "Subnet CIDR for private endpoints."
  type        = string
  default     = "10.20.3.0/24"
}

variable "enable_private_endpoints" {
  description = "Create private DNS zones/links for Key Vault and ACR (prod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

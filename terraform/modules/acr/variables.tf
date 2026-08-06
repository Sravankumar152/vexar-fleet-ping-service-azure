variable "acr_name" {
  description = "Globally-unique ACR name (alphanumeric, 5-50 chars)."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  description = "ACR SKU. Basic is fine for one service; Premium enables PE + geo-replication."
  type        = string
  default     = "Basic"
}

variable "public_network_access_enabled" {
  description = "Whether the registry is reachable from the internet."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Create a private endpoint (requires Premium SKU)."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "geo_replication_locations" {
  description = "Extra regions to replicate to (Premium only)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

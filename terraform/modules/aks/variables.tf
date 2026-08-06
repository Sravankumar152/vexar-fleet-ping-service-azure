variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  description = "AKS control-plane version."
  type        = string
  default     = "1.30"
}

variable "sku_tier" {
  description = "Free (dev) or Standard (prod, financially-backed SLA)."
  type        = string
  default     = "Free"
}

variable "aks_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "acr_id" {
  type = string
}

# --- System node pool ---
variable "system_node_vm_size" {
  description = "Node VM size. Standard_B2s (burstable) is cheap for dev."
  type        = string
  default     = "Standard_B2s"
}

variable "system_node_min_count" {
  type    = number
  default = 1
}

variable "system_node_max_count" {
  type    = number
  default = 3
}

variable "dedicated_system_pool" {
  description = "Taint the system pool so only critical addons run on it (prod)."
  type        = bool
  default     = false
}

# --- Spot user pool ---
variable "enable_spot_pool" {
  type    = bool
  default = false
}

variable "spot_node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "spot_node_max_count" {
  type    = number
  default = 3
}

# --- Networking ---
variable "service_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.30.0.10"
}

variable "pod_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "private_cluster_enabled" {
  description = "Private API server (recommended for prod)."
  type        = bool
  default     = false
}

variable "local_account_disabled" {
  description = "Disable local (non-AAD) admin accounts. True for prod."
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "AAD group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

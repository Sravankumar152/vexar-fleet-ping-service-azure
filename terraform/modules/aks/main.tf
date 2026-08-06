# -----------------------------------------------------------------------------
# Azure Kubernetes Service
# Cost-efficient, production-reliable cluster:
# - Free control-plane tier in dev, Standard (SLA) in prod
# - Single small autoscaling system node pool (Azure CNI Overlay)
# - Workload Identity (OIDC) + Key Vault CSI driver — pods get secrets without
#   any secret material on disk
# - Container Insights shipped to the shared Log Analytics workspace
# - Optional Spot user pool for cheap burst capacity (off by default)
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # Keep the API server private in prod; public (dev) for easy kubectl access.
  private_cluster_enabled           = var.private_cluster_enabled
  role_based_access_control_enabled = true
  local_account_disabled            = var.local_account_disabled
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_vm_size
    vnet_subnet_id      = var.aks_subnet_id
    enable_auto_scaling = true
    min_count           = var.system_node_min_count
    max_count           = var.system_node_max_count
    os_disk_size_gb     = 64
    # Managed OS disk works on every SKU (Ephemeral needs a cache/temp disk the
    # small burstable/Dsv5 SKUs used here don't provide).
    os_disk_type                 = "Managed"
    only_critical_addons_enabled = var.dedicated_system_pool
    temporary_name_for_rotation  = "systmp"
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # AAD-integrated Kubernetes RBAC; scope cluster-admin to a specific AAD group.
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    # "azure" network policy is universally supported; Cilium can be enabled
    # later via ebpf_data_plane for eBPF policy/observability.
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    pod_cidr          = var.pod_cidr
  }

  # Ship container stdout/stderr + metrics to Log Analytics (Container Insights).
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Managed Key Vault CSI driver: mount secrets as files / sync to K8s secrets.
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Patch during a low-traffic window rather than at random.
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+00:00"
    duration    = 4
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
    expander                    = "least-waste"
    scale_down_unneeded         = "10m"
  }

  lifecycle {
    ignore_changes = [
      # Patch version drifts as Azure applies node image upgrades.
      default_node_pool[0].node_count,
    ]
  }

  tags = var.tags
}

# Optional Spot user pool for cheap, interruptible burst capacity.
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.enable_spot_pool ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.spot_node_vm_size
  vnet_subnet_id        = var.aks_subnet_id
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1 # pay up to the on-demand price
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = var.spot_node_max_count
  os_disk_type          = "Managed"

  node_labels = {
    "workload-type" = "burst"
  }
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]
  tags = var.tags
}

# Allow the cluster's kubelet identity to pull images from ACR.
resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

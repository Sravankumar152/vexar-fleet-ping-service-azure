# -----------------------------------------------------------------------------
# Azure Container Registry
# Basic SKU is enough for a single service. Admin user is disabled — pulls use
# the AKS kubelet managed identity (AcrPull), pushes use the CI OIDC identity.
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "this" {
  name                          = var.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  # Retention/geo-replication are Premium-only; documented as a prod upgrade.
  dynamic "georeplications" {
    for_each = var.geo_replication_locations
    content {
      location = georeplications.value
      tags     = var.tags
    }
  }
}

# Private endpoint (prod). Kept optional to avoid Premium/PE cost in dev.
resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.acr_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# -----------------------------------------------------------------------------
# Azure Key Vault (RBAC-authorized)
# Holds application secrets (DB password, JWT signing key, connection info).
# Access is granted via Azure RBAC + Managed Identity only — no access policies,
# no admin credentials. Optionally fronted by a private endpoint in prod.
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # RBAC instead of access policies: cleaner least-privilege, auditable in AAD.
  enable_rbac_authorization = true

  # Protect against accidental/malicious deletion of secrets.
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = 7

  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass         = "AzureServices"
    default_action = var.public_network_access_enabled ? "Allow" : "Deny"
    ip_rules       = var.allowed_ip_rules
  }

  tags = var.tags
}

# Let the identity running Terraform manage secrets (needed to seed values).
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = coalesce(var.deployer_principal_id, data.azurerm_client_config.current.object_id)
}

# Private endpoint (prod).
resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

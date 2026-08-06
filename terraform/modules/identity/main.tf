# -----------------------------------------------------------------------------
# Application workload identity
# A user-assigned managed identity federated to the app's Kubernetes service
# account. The pod exchanges its projected SA token for an AAD token — no
# client secret anywhere. The identity is granted read-only access to the
# app's Key Vault secrets (least privilege).
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.name_prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Federate the identity to the in-cluster service account.
resource "azurerm_federated_identity_credential" "app" {
  name                = "fic-${var.name_prefix}-app"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.app.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
}

# Least privilege: read secrets only (not manage them).
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

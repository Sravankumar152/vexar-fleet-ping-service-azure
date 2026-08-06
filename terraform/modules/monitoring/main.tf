# -----------------------------------------------------------------------------
# Monitoring & observability
# Log Analytics workspace (Container Insights sink + app logs), an action group
# for notifications, and the metric alerts that matter for this service.
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  # Daily cap keeps ingestion cost predictable in non-prod (-1 = no cap).
  daily_quota_gb = var.daily_quota_gb
  tags           = var.tags
}

resource "azurerm_monitor_action_group" "this" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.alert_emails
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = var.tags
}

# --- PostgreSQL alerts -------------------------------------------------------

resource "azurerm_monitor_metric_alert" "pg_cpu" {
  name                = "alert-pg-cpu-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.postgres_server_id]
  description         = "PostgreSQL CPU sustained high — risk of ping-ingestion latency/timeouts."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "pg_storage" {
  name                = "alert-pg-storage-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.postgres_server_id]
  description         = "PostgreSQL storage nearly full — writes will fail if it reaches 100%."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "pg_connections" {
  name                = "alert-pg-conns-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.postgres_server_id]
  description         = "PostgreSQL connections approaching the server limit — pool/pgbouncer pressure."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "active_connections"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.pg_connection_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
  tags = var.tags
}

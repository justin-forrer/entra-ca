# Alerts on any sign-in by, or directory change to, the break-glass accounts, their
# group or their restricted admin unit. Entra logs are exported to Log Analytics,
# and two log search alert rules email the action group.

locals {
  monitoring_tags = merge(local.tags, { purpose = "break-glass-monitoring" })

  # Read from the group, so a new account is covered on the next apply.
  break_glass_user_ids = data.azuread_group.break_glass.members

  # Every object whose changes should alert: the unit, the group and each account.
  break_glass_object_ids = concat(
    [msgraph_resource.break_glass_au.id, data.azuread_group.break_glass.object_id],
    local.break_glass_user_ids,
  )
}

# Fired alerts are stored by Microsoft.AlertsManagement. The provider is set to
# register nothing automatically, so it is registered here.
resource "azurerm_resource_provider_registration" "alerts_management" {
  name = "Microsoft.AlertsManagement"
}

resource "azurerm_resource_group" "monitoring" {
  location = "eastus"
  name     = "rg-entra-ca-monitoring"
  tags     = local.monitoring_tags
}

resource "azurerm_log_analytics_workspace" "entra" {
  location            = azurerm_resource_group.monitoring.location
  name                = "log-entra-ca"
  resource_group_name = azurerm_resource_group.monitoring.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
  tags                = local.monitoring_tags
}

resource "azurerm_monitor_aad_diagnostic_setting" "entra" {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.entra.id
  name                       = "entra-ca-break-glass"

  enabled_log {
    category = "AuditLogs"
  }
  enabled_log {
    category = "SignInLogs"
  }
  enabled_log {
    category = "NonInteractiveUserSignInLogs"
  }
}

resource "azurerm_monitor_action_group" "break_glass" {
  name                = "ag-break-glass"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "breakglass"
  tags                = local.monitoring_tags

  email_receiver {
    email_address           = var.alert_email
    name                    = "security-contact"
    use_common_alert_schema = true
  }
}

# Both rules check the last 5 minutes every 5 minutes, so each event is evaluated
# once. Azure Monitor retries an evaluation when log data arrives late, so the
# windows don't need to overlap. Actions are never muted: muting would hide a
# second event that happens soon after the first.

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "break_glass_sign_in" {
  description          = "Any sign-in attempt, interactive or not, by a break-glass account."
  display_name         = "Break-glass account sign-in"
  evaluation_frequency = "PT5M"
  location             = azurerm_resource_group.monitoring.location
  name                 = "alert-break-glass-sign-in"
  resource_group_name  = azurerm_resource_group.monitoring.name
  scopes               = [azurerm_log_analytics_workspace.entra.id]
  severity             = 0
  tags                 = local.monitoring_tags
  window_duration      = "PT5M"

  depends_on = [azurerm_resource_provider_registration.alerts_management]

  criteria {
    operator                = "GreaterThan"
    threshold               = 0
    time_aggregation_method = "Count"
    query                   = <<-KQL
      union SigninLogs, AADNonInteractiveUserSignInLogs
      | where UserId in (dynamic(${jsonencode(local.break_glass_user_ids)}))
      | project TimeGenerated, Type, UserPrincipalName, AppDisplayName, IPAddress, ResultType
    KQL

    # One alert per account, so a sign-in to each sends its own email that names it.
    dimension {
      name     = "UserPrincipalName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.break_glass.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "break_glass_change" {
  description          = "Any directory change to, or by, the break-glass accounts, their group or their restricted admin unit."
  display_name         = "Break-glass account or admin unit change"
  evaluation_frequency = "PT5M"
  location             = azurerm_resource_group.monitoring.location
  name                 = "alert-break-glass-change"
  resource_group_name  = azurerm_resource_group.monitoring.name
  scopes               = [azurerm_log_analytics_workspace.entra.id]
  severity             = 0
  tags                 = local.monitoring_tags
  window_duration      = "PT5M"

  depends_on = [azurerm_resource_provider_registration.alerts_management]

  criteria {
    operator                = "GreaterThan"
    threshold               = 0
    time_aggregation_method = "Count"
    # Matching on object IDs anywhere in the target or initiator catches member,
    # role, credential and property changes without listing every activity name.
    # The restricted-unit activities are matched by name as well, because a role
    # scoped to the unit doesn't always name the unit as a target.
    query = <<-KQL
      let ids = dynamic(${jsonencode(local.break_glass_object_ids)});
      AuditLogs
      | where tostring(TargetResources) has_any (ids)
          or tostring(InitiatedBy) has_any (ids)
          or OperationName contains "restricted management administrative unit"
      | project TimeGenerated, OperationName, Result, InitiatedBy, TargetResources
    KQL
  }

  action {
    action_groups = [azurerm_monitor_action_group.break_glass.id]
  }
}

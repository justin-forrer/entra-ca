resource "azuread_conditional_access_policy" "this" {
  for_each = var.policies

  display_name = each.value.display_name
  state        = each.value.state

  conditions {
    client_app_types                     = each.value.client_app_types
    sign_in_risk_levels                  = each.value.sign_in_risk_levels
    user_risk_levels                     = each.value.user_risk_levels
    authentication_flow_transfer_methods = each.value.authentication_flow_transfer_methods

    applications {
      included_applications = each.value.included_applications
      excluded_applications = each.value.excluded_applications
    }

    users {
      included_users  = each.value.included_users
      excluded_users  = each.value.excluded_users
      included_groups = each.value.included_groups
      excluded_groups = concat(coalesce(each.value.excluded_groups, []), [var.break_glass_group_id])
      included_roles  = each.value.included_roles
      excluded_roles  = each.value.excluded_roles
    }
  }

  dynamic "grant_controls" {
    for_each = each.value.grant != null ? [each.value.grant] : []

    content {
      operator                          = grant_controls.value.operator
      built_in_controls                 = grant_controls.value.built_in_controls
      authentication_strength_policy_id = grant_controls.value.authentication_strength_policy_id
    }
  }

  dynamic "session_controls" {
    for_each = each.value.session == null ? [] : [each.value.session]

    content {
      sign_in_frequency                         = session_controls.value.sign_in_frequency
      sign_in_frequency_period                  = session_controls.value.sign_in_frequency_period
      sign_in_frequency_interval                = session_controls.value.sign_in_frequency_interval
      sign_in_frequency_authentication_type     = session_controls.value.sign_in_frequency_authentication_type
      persistent_browser_mode                   = session_controls.value.persistent_browser_mode
      disable_resilience_defaults               = session_controls.value.disable_resilience_defaults
      application_enforced_restrictions_enabled = session_controls.value.application_enforced_restrictions_enabled
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
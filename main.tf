resource "azuread_conditional_access_policy" "ca001_block_legacy_auth" {
  display_name = "CA001 - Block Legacy Authentication"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = [data.azuread_group.break_glass.object_id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }

  lifecycle {
    prevent_destroy = true
  }

}
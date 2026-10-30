variable "break_glass_group_id" {
  description = "Group excluded from every policy. Appended to each policy's excluded_groups list. This group should contain emergency access (breakglass) accounts in Entra ID."
  type        = string
}

variable "policies" {
  description = "Conditional access policies keyed by a stable identifier"
  type = map(object({
    display_name = string
    state        = optional(string, "enabledForReportingButNotEnforced")

    client_app_types      = optional(list(string), ["all"])
    included_applications = optional(list(string), ["All"])
    excluded_applications = optional(list(string))

    included_users  = optional(list(string))
    excluded_users  = optional(list(string))
    included_groups = optional(list(string))
    excluded_groups = optional(list(string))
    included_roles  = optional(list(string))
    excluded_roles  = optional(list(string))

    sign_in_risk_levels = optional(list(string))
    user_risk_levels    = optional(list(string))

    authentication_flow_transfer_methods = optional(list(string))

    grant = optional(object({
      operator                          = optional(string, "OR")
      built_in_controls                 = optional(list(string))
      authentication_strength_policy_id = optional(string)
    }))
    session = optional(object({
      sign_in_frequency                         = optional(number)
      sign_in_frequency_period                  = optional(string)
      sign_in_frequency_interval                = optional(string)
      sign_in_frequency_authentication_type     = optional(string)
      persistent_browser_mode                   = optional(string)
      disable_resilience_defaults               = optional(bool)
      application_enforced_restrictions_enabled = optional(bool)

    }))
  }))

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], p.state)
    ])
    error_message = "Each policy state must be enabled, disabled, or enabledForReportingButNotEnforced."
  }
} 
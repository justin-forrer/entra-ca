variable "tenant_id" {
  description = "The Entra tenant ID."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.tenant_id))
    error_message = "Invalid tenant ID format. tenant_id must be a valid GUID."
  }
}

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.subscription_id))
    error_message = "Invalid subscription ID format. subscription_id must be a valid GUID."
  }
}

variable "break_glass_group_object_id" {
  description = "Object ID of the group holding emergency access (break-glass) accounts."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.break_glass_group_object_id))
    error_message = "Invalid group object ID format. break_glass_group_object_id must be a valid GUID."
  }
}

variable "alert_email" {
  description = "Email address notified when a break-glass account signs in or is changed."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

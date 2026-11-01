data "azuread_group" "break_glass" {
  object_id = var.break_glass_group_object_id

  lifecycle {
    postcondition {
      condition     = length(self.members) >= 2
      error_message = "The break glass group must have at least 2 members."
    }
    postcondition {
      condition     = length(self.owners) == 0
      error_message = "The break glass group must have no owners."
    }
  }
}

# azuread can't set isMemberManagementRestricted, and Entra only accepts it at
# creation, so the unit is created through the msgraph provider.
resource "msgraph_resource" "break_glass_au" {
  url = "directory/administrativeUnits"
  body = {
    displayName                  = "RMAU - Emergency Access"
    description                  = "Protects break-glass accounts and their group. Managed by Terraform (bootstrap/)."
    isMemberManagementRestricted = true
  }
  response_export_values = {
    restricted = "isMemberManagementRestricted"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Adding a group to an administrative unit doesn't add its members, so the group
# and each account are enrolled directly.
resource "azuread_administrative_unit_member" "break_glass" {
  for_each = toset(concat(
    [data.azuread_group.break_glass.object_id],
    data.azuread_group.break_glass.members,
  ))

  administrative_unit_object_id = msgraph_resource.break_glass_au.id
  member_object_id              = each.value
}

output "break_glass_au_object_id" {
  description = "Object ID of the restricted management administrative unit."
  value       = msgraph_resource.break_glass_au.id
}

output "break_glass_au_restricted" {
  description = "Whether Entra reports the unit as restricted. Must be true."
  value       = msgraph_resource.break_glass_au.output.restricted
}

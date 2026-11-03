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

data "azuread_administrative_unit" "break_glass" {
  object_id = var.break_glass_au_object_id
  lifecycle {
    postcondition {
      condition = length(setsubtract(
        toset(concat([data.azuread_group.break_glass.object_id],
        data.azuread_group.break_glass.members)),
        toset(self.members),
      )) == 0
      error_message = "The break glass group and all its members must be in the restricted admin unit."
    }
  }
}
data "azuread_group" "break_glass" {
  object_id = var.break_glass_group_object_id


  lifecycle {
    postcondition {
      condition     = length(self.members) >= 2
      error_message = "The break glass group must have at least 2 members."
    }
  }
}
module "conditional_access" {
  source = "./modules/conditional-access"

  break_glass_group_id = data.azuread_group.break_glass.object_id
  policies             = local.policies
}

moved {
  from = azuread_conditional_access_policy.ca001_block_legacy_auth
  to   = module.conditional_access.azuread_conditional_access_policy.this["ca001_block_legacy_auth"]
}
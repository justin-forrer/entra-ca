output "policy_ids" {
  description = "The IDs of the conditional access policies created by this module. keyed by policy key"
  value       = { for k, p in azuread_conditional_access_policy.this : k => p.id }
}
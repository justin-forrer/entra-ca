# entra-ca

Terraform configuration for managing Microsoft Entra ID Conditional Access policies as code.

Policies are declared as data in a single `locals` block and rendered by one reusable module, so adding a policy means adding a map entry — not writing another resource.

## Requirements

| Requirement | Version |
| --- | --- |
| Terraform | >= 1.6 |
| `hashicorp/azuread` provider | >= 3.0 (locked at 3.10.0) |

The provider is configured with `tenant_id` only, so credentials come from the ambient
environment — `az login` for local use, or the `ARM_*` / `AZURE_*` environment variables
in CI.

The identity running Terraform needs permission to read and write Conditional Access
policies (for example the **Conditional Access Administrator** or **Security Administrator**
role, i.e. the `Policy.ReadWrite.ConditionalAccess` and `Policy.Read.All` permissions), plus
directory read access for the break-glass group lookup in `data.tf`.

## Layout

```
.
├── versions.tf                      # Terraform + azuread provider constraints, provider config
├── variables.tf                     # tenant_id, break_glass_group_object_id
├── terraform.tfvars                 # local values (gitignored)
├── data.tf                          # break-glass group lookup + membership guardrail
├── conditional_access_policies.tf   # local.policies — the policy catalog
├── main.tf                          # module call + moved block
├── outputs.tf                       # policy_ids
└── modules/conditional-access/      # renders local.policies into azuread_conditional_access_policy
```

## Inputs

Set these in `terraform.tfvars` (gitignored — it is not checked in, so each operator
supplies their own):

| Variable | Description |
| --- | --- |
| `tenant_id` | Entra tenant ID. Validated as a GUID. |
| `break_glass_group_object_id` | Object ID of the group holding emergency access (break-glass) accounts. |

```hcl
tenant_id                   = "00000000-0000-0000-0000-000000000000"
break_glass_group_object_id = "00000000-0000-0000-0000-000000000000"
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

`terraform output policy_ids` returns a map of policy key → Entra policy ID.

## Safety behaviours

These are built into the configuration and apply to every policy:

- **Break-glass exclusion.** The module appends `var.break_glass_group_id` to every
  policy's `excluded_groups`, so emergency access accounts can never be locked out by a
  policy managed here.
- **Break-glass group must be populated.** A `postcondition` in `data.tf` fails the plan
  if the group has fewer than 2 members.
- **Report-only by default.** A policy with no explicit `state` is created as
  `enabledForReportingButNotEnforced`. Enforcement is opt-in per policy.
- **`prevent_destroy`.** Policies cannot be destroyed by Terraform. To retire one, set
  `state = "disabled"` rather than deleting its map entry — removing the entry makes
  `for_each` plan a destroy, which `prevent_destroy` will reject.
- **State validation.** `state` must be `enabled`, `disabled`, or
  `enabledForReportingButNotEnforced`.

## Current policies

| Key | Display name | State | Effect |
| --- | --- | --- | --- |
| `ca001_block_legacy_auth` | CA001 - Block Legacy Authentication | `enabled` | Blocks `exchangeActiveSync` and `other` (legacy) clients for all users. |
| `ca002_mfa_admins` | CA002 - Require MFA for Administrators | `enabled` | Requires MFA for Global Admin, Privileged Role Admin, Security Admin, and Conditional Access Admin. |
| `ca003_mfa_all_users` | CA003 - Require MFA for All Users | `enabled` | Requires MFA for all users. |
| `ca004_block_device_code_flow` | CA004 - Block Device Code Flow | report-only | Blocks the device code authentication flow for all users, closing off device code phishing. |

## Adding a policy

Add an entry to `local.policies` in `conditional_access_policies.tf`. The key becomes the
`for_each` address, so pick it carefully — renaming it plans a destroy and recreate
(which `prevent_destroy` will block) unless you add a `moved` block in `main.tf` mapping
the old key to the new one.

```hcl
ca005_block_unmanaged_devices = {
  display_name   = "CA005 - Block Unmanaged Devices"
  included_users = ["All"]
  grant = {
    built_in_controls = ["compliantDevice"]
  }
  # state omitted -> report-only
}
```

Run `terraform plan`, review the report-only policy in the Entra portal's
**Conditional Access > Insights and reporting** workbook, then add `state = "enabled"`
in a follow-up change.

### Policy schema

Defined by the `policies` variable in `modules/conditional-access/variables.tf`.

| Field | Type | Default |
| --- | --- | --- |
| `display_name` | `string` | required |
| `state` | `string` | `"enabledForReportingButNotEnforced"` |
| `client_app_types` | `list(string)` | `["all"]` |
| `included_applications` | `list(string)` | `["All"]` |
| `excluded_applications` | `list(string)` | unset |
| `included_users` | `list(string)` | unset |
| `excluded_users` | `list(string)` | unset |
| `included_groups` | `list(string)` | unset |
| `excluded_groups` | `list(string)` | unset (break-glass group always appended) |
| `included_roles` | `list(string)` | unset |
| `excluded_roles` | `list(string)` | unset |
| `sign_in_risk_levels` | `list(string)` | unset (requires P2) |
| `user_risk_levels` | `list(string)` | unset (requires P2) |
| `authentication_flow_transfer_methods` | `list(string)` | unset (`deviceCodeFlow`, `authenticationTransfer`) |
| `grant.operator` | `string` | `"OR"` |
| `grant.built_in_controls` | `list(string)` | unset |
| `grant.authentication_strength_policy_id` | `string` | unset |
| `session.sign_in_frequency` | `number` | unset |
| `session.sign_in_frequency_period` | `string` | unset |
| `session.sign_in_frequency_interval` | `string` | unset |
| `session.sign_in_frequency_authentication_type` | `string` | unset |
| `session.persistent_browser_mode` | `string` | unset |
| `session.disable_resilience_defaults` | `bool` | unset |
| `session.application_enforced_restrictions_enabled` | `bool` | unset |

Omit `grant` or `session` entirely when a policy needs no grant or session controls; the
module only emits the `grant_controls` / `session_controls` blocks when they are non-null.

## Notes

- `main.tf` contains a `moved` block tracking CA001's migration from a root-level resource
  into the module. It can be deleted once every state file has been applied past that
  migration.
- State is local (`terraform.tfstate`) and gitignored. Moving to a remote backend is
  worth doing before more than one person applies this configuration.

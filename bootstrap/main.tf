resource "azurerm_resource_group" "tfstate" {
  location = "eastus"
  name     = "rg-entra-ca-tfstate"
  tags     = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  container_access_type = "private"
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
}

resource "azurerm_storage_container" "bootstrap" {
  container_access_type = "private"
  name                  = "tfstate-bootstrap"
  storage_account_id    = azurerm_storage_account.tfstate.id
}

resource "azurerm_storage_account" "tfstate" {
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  allowed_copy_scope              = "AAD"
  default_to_oauth_authentication = true
  location                        = azurerm_resource_group.tfstate.location
  min_tls_version                 = "TLS1_2"
  name                            = "jforrerentracatfstate"
  resource_group_name             = azurerm_resource_group.tfstate.name
  shared_access_key_enabled       = false
  tags                            = local.tags

  blob_properties {
    versioning_enabled = true
    container_delete_retention_policy {
      days = 7
    }
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azuread_application" "apply" {
  display_name     = "entra-ca-apply"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    resource_access {
      id   = "5b567255-7703-4780-807c-7be8301ae99b" # Group.Read.All
      type = "Role"
    }
    resource_access {
      id   = "246dd0d5-5bd0-4def-940b-0421030a5b68" # Policy.Read.All
      type = "Role"
    }
    resource_access {
      id   = "01c0a623-fc9b-48e9-b794-0756f8e8f067" # Policy.ReadWrite.ConditionalAccess
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "apply" {
  client_id = azuread_application.apply.client_id
}

resource "azuread_application" "plan" {
  display_name     = "entra-ca-plan"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    resource_access {
      id   = "5b567255-7703-4780-807c-7be8301ae99b" # Group.Read.All
      type = "Role"
    }
    resource_access {
      id   = "246dd0d5-5bd0-4def-940b-0421030a5b68" # Policy.Read.All
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "plan" {
  client_id = azuread_application.plan.client_id
}

resource "azuread_application_federated_identity_credential" "plan" {
  application_id = azuread_application.plan.id
  display_name   = "github-pr"
  description    = "GitHub Actions plan on pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:justin-forrer@60010282/entra-ca@1439254096:pull_request"
}

resource "azuread_application_federated_identity_credential" "apply" {
  application_id = azuread_application.apply.id
  display_name   = "github-production"
  description    = "GitHub Actions apply from production environment"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:justin-forrer@60010282/entra-ca@1439254096:environment:production"
}

data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

resource "azuread_app_role_assignment" "plan_group_read" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
  principal_object_id = azuread_service_principal.plan.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "plan_policy_read" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Policy.Read.All"]
  principal_object_id = azuread_service_principal.plan.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "apply_group_read" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
  principal_object_id = azuread_service_principal.apply.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "apply_policy_read" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Policy.Read.All"]
  principal_object_id = azuread_service_principal.apply.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "apply_ca_write" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Policy.ReadWrite.ConditionalAccess"]
  principal_object_id = azuread_service_principal.apply.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azurerm_role_assignment" "plan_state" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.plan.object_id
}

resource "azurerm_role_assignment" "apply_state" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.apply.object_id
}

locals {
  tags = {
    environment = "lab"
    managed-by  = "terraform"
    owner       = "justin"
    purpose     = "terraform-state"
    workload    = "entra-ca"
  }
}
terraform {
  required_version = ">= 1.6"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-entra-ca-tfstate"
    storage_account_name = "jforrerentracatfstate"
    container_name       = "tfstate-bootstrap"
    key                  = "bootstrap.tfstate"
    use_azuread_auth     = true
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
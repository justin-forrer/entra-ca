terraform {
  required_version = ">= 1.6"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-entra-ca-tfstate"
    storage_account_name = "jforrerentracatfstate"
    container_name       = "tfstate"
    key                  = "entra-ca.tfstate"
    use_azuread_auth     = true
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}
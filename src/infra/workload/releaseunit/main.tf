terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.83.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      # Allows the deletion of non-empty resource groups
      # This is required to delete rgs with stale resources left
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      recover_soft_deleted_key_vaults       = true
      purge_soft_delete_on_destroy          = false # required when purge is not possible
      purge_soft_deleted_secrets_on_destroy = false # required when purge is not possible
    }
  }
}

# Random API key which needs to be identical between all stamps
resource "random_password" "api_key" {
  length  = 32
  special = false
}

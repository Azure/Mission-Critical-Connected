terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    # Purge APIM on destroy (the default is to only soft-delete it)
    api_management {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Random API key which needs to be identical between all stamps
resource "random_password" "api_key" {
  length  = 32
  special = false
}

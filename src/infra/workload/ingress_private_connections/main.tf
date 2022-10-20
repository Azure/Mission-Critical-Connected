terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

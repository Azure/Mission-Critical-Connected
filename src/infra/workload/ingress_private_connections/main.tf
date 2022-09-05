terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.21.1"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

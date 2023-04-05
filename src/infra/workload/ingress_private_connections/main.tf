terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

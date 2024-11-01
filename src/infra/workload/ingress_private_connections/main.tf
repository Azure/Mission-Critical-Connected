terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.8.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.1"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

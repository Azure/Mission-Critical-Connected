terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

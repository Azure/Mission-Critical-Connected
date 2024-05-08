terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

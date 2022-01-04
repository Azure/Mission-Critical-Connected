data "azurerm_resource_group" "buildagent" {
  name = var.buildagent_resource_group_name
}

data "azurerm_virtual_network" "buildagent" {
  name                = var.buildagent_vnet_name
  resource_group_name = var.buildagent_resource_group_name
}
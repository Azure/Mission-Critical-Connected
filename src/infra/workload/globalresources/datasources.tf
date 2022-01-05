data "azurerm_resource_group" "buildagent" {
  name = "${var.prefix}-buildagents-rg"
}

data "azurerm_virtual_network" "buildagent" {
  name                = "${var.prefix}-buildagents-vnet"
  resource_group_name = data.azurerm_resource_group.buildagent.name
}
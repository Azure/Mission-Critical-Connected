data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "buildagent" {
  name = "${var.prefix}-buildinfra-rg"
}

data "azurerm_virtual_network" "buildagent" {
  name                = "${var.prefix}buildinfra-vnet"
  resource_group_name = data.azurerm_resource_group.buildagent.name
}

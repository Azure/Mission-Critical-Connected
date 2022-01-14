# Dynamically calculate subnet addresses from the overall address space. Assumes (at least) a /20 address space
# Uses the Hashicopr module "CIDR subnets" https://registry.terraform.io/modules/hashicorp/subnets/cidr/latest
locals {
  netmask = tonumber(split("/", var.vnet_address_space)[1]) # Take the last part from the address space 10.0.0.0/16 => 16
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vnet_address_space
  networks = [
    {
      name     = "buildagents-vmss"
      new_bits = 24 - local.netmask # For Build Agents VMSS we want a /24 sized subnet. So we calculate based on the provided input address space # Size: /24
    },
    {
      name     = "jumpservers-vmss"
      new_bits = 24 - local.netmask # For Jump Server VMSS we want a /24 sized subnet.
    },
    {
      name     = "bastion"
      new_bits = 27 - local.netmask # For the Bastion subnet we need a /27 sized subnet.
    },
    {
      name     = "private-endpoints"
      new_bits = 24 - local.netmask # For the private endpoints we want a /24 sized subnet.
    }
  ]
}

resource "azurerm_virtual_network" "deployment" {
  name                = "${local.prefix}-vnet"
  address_space       = [module.subnet_addrs.base_cidr_block]
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags

  subnet {
    name           = "buildagents-snet"
    address_prefix = module.subnet_addrs.network_cidr_blocks["buildagents-vmss"]
    security_group = azurerm_network_security_group.default.id
  }

  subnet {
    name           = "jumpservers-snet"
    address_prefix = module.subnet_addrs.network_cidr_blocks["jumpservers-vmss"]
    security_group = azurerm_network_security_group.default.id
  }

  subnet {
    name           = "AzureBastionSubnet"
    address_prefix = module.subnet_addrs.network_cidr_blocks["bastion"]
    security_group = azurerm_network_security_group.default.id
  }

  subnet {
    name           = "private-endpoints-snet"
    address_prefix = module.subnet_addrs.network_cidr_blocks["private-endpoints"]
    security_group = azurerm_network_security_group.default.id
  }
}

# Default Network Security Group (nsg) definition
# Allows outbound and intra-vnet/cross-subnet communication
resource "azurerm_network_security_group" "default" {
  name                = "${local.prefix}-nsg"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name

  # not specifying any security_rules {} will create Azure's default set of NSG rules
  # it allows intra-vnet communication and public internet access

  tags = local.default_tags
}

# Network Security Group (nsg) for Azure Bastion subnets
# https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg
resource "azurerm_network_security_group" "azurebastion" {
  name                = "${local.prefix}-bastion-nsg"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name

  security_rule {
    name                       = "GatewayManager"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Internet-Bastion-PublicIP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OutboundVirtualNetwork"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "OutboundToAzureCloud"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.default_tags
}

# Dynamically calculate subnet addresses from the overall address space.
# Based on the subnet sizes of /24 for kubernetes, (at least) a /23 address space is needed
#
# To change the subnet sizes, change the values in the subnet_addrs.networks array below (the new_bits setting)
#

# Uses the Hashicorp module "CIDR subnets" https://registry.terraform.io/modules/hashicorp/subnets/cidr/latest
locals {
  netmask = tonumber(split("/", data.azurerm_virtual_network.stamp.address_space[0])[1]) # Take the last part from the address space 10.0.0.0/16 => 16
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = data.azurerm_virtual_network.stamp.address_space[0]
  networks = [
    {
      name     = "kubernetes"
      new_bits = 24 - local.netmask # For AKS we want a /24 sized subnet. So we calculate based on the provided input address space
    },
    {
      name     = "private-endpoints"
      new_bits = 27 - local.netmask # For the private endpoints we want a /27 sized subnet. So we calculate based on the provided input address space
    }
  ]
}

# Default Network Security Group (nsg) definition
# Allows outbound and intra-vnet/cross-subnet communication
resource "azurerm_network_security_group" "default" {
  name                = "${local.prefix}-${local.location_short}-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name

  # not specifying any security_rules {} will create Azure's default set of NSG rules
  # it allows intra-vnet communication and outbound public internet access

  tags = var.default_tags
}

# Adding an explicit inbound rule for the AKS ingress controller TCP/80 and TCP/443
# This is done as a separate security rule resource to not override the defaults
resource "azurerm_network_security_rule" "allow_inbound_https" {
  name                        = "Allow_Inbound_HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.aks_ingress.ip_address
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.default.name
}

# Subnet for Kubernetes nodes and pods
resource "azurerm_subnet" "kubernetes" {
  name                 = "kubernetes-snet"
  resource_group_name  = local.vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.stamp.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["kubernetes"]]
  service_endpoints = [
    "Microsoft.Storage"
  ]

  enforce_private_link_endpoint_network_policies = true
}

# NSG - Assign default nsg to kubernetes-snet subnet
resource "azurerm_subnet_network_security_group_association" "kubernetes_default_nsg" {
  subnet_id                 = azurerm_subnet.kubernetes.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "private-endpoints-snet"
  resource_group_name  = local.vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.stamp.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["private-endpoints"]]

  enforce_private_link_endpoint_network_policies = true
}

# NSG - Assign default nsg to private-endpoints-snet subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints_default_nsg" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.default.id
}

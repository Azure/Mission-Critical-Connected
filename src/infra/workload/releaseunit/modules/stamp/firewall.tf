resource "azurerm_firewall" "stamp" {
  name                = "${local.prefix}-${local.location_short}-fw"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_application_rule_collection" "aksbasics" {
  name                = "aksbasics"
  azure_firewall_name = azurerm_firewall.stamp.name
  resource_group_name = azurerm_resource_group.stamp.name
  priority            = 101
  action              = "Allow"

  rule {
    name             = "allow network"
    source_addresses = ["*"]

    target_fqdns = [
      "*.cdn.mscr.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "acs-mirror.azureedge.net",
      "dc.services.visualstudio.com",
      "*.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.microsoftonline.com",
      "*.monitoring.azure.com",
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "${local.prefix}-${local.location_short}-fw-pip"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_route_table" "kubernetes" {
  name                = "${local.prefix}-${local.location_short}-aks-rt"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name

  route {
    name                   = "kubenetfw_fw_r"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.stamp.ip_configuration.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "kubernetes_subnet_association" {
  subnet_id      = azurerm_subnet.kubernetes.id
  route_table_id = azurerm_route_table.kubernetes.id
}
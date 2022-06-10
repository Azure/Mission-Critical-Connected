resource "azurerm_dns_zone" "stamp_dns_zone" {
  name                = "stamp.mydomain.com"
  resource_group_name = azurerm_resource_group.stamp.name
}
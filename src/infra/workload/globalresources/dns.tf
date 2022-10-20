data "azurerm_dns_zone" "customdomain" {
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

# CNAME to point to the Front Door
resource "azurerm_dns_cname_record" "afd_subdomain" {
  name                = var.front_door_subdomain
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = data.azurerm_dns_zone.customdomain.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.default.host_name

  tags = local.default_tags
}

# TXT record for Front Door custom domain validation
resource "azurerm_dns_txt_record" "global" {
  name                = "_dnsauth.${var.front_door_subdomain}"
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = data.azurerm_dns_zone.customdomain.resource_group_name
  ttl                 = 3600
  record {
    value = azurerm_cdn_frontdoor_custom_domain.global.validation_token
  }
}
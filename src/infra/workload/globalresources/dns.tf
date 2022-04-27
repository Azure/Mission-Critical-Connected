// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  name                = local.custom_domain_name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

resource "azurerm_dns_cname_record" "afd_subdomain" {
  name                = local.custom_domain_subdomain
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.default.host_name
}
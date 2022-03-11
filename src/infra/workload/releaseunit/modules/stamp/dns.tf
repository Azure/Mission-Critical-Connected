// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

resource "azurerm_dns_a_record" "cluster_subdomain" {
  name                = "${local.prefix}-${local.location_short}-ingress-private"
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
  ttl                 = 3600
  records             = [local.aks_internal_lb_ip_address]
}
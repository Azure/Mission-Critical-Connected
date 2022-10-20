// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

# A record for the AKS ingress controller (points to private IP address of the ingress controller LB)
resource "azurerm_dns_a_record" "cluster_ingress" {
  name                = "internal.ingress.${var.location}.${local.prefix}"
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = data.azurerm_dns_zone.customdomain.resource_group_name
  ttl                 = 3600
  records             = [local.aks_internal_lb_ip_address]

  tags = var.default_tags
}
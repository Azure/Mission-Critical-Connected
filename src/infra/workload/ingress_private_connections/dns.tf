// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

# A record for the AKS ingress controller (points to private IP address of the ingress controller LB)
resource "azurerm_dns_a_record" "build_agent_ingress_private_endpoint" {
  for_each            = var.private_link_service_targets

  name                = "ingress.${each.key}.${local.prefix}.buildagent"
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = data.azurerm_dns_zone.customdomain.resource_group_name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.buildagent_aks[each.key].custom_dns_configs.0.ip_addresses.0]
}
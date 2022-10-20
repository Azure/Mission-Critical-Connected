data "azurerm_dns_zone" "customdomain" {
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

# A record for the AKS ingress controller (points to private IP address of the ingress controller LB)
resource "azurerm_dns_a_record" "build_agent_ingress_private_endpoint" {
  for_each = var.private_link_service_targets

  name                = "buildagent.ingress.${each.key}.${local.prefix}"
  zone_name           = data.azurerm_dns_zone.customdomain.name
  resource_group_name = data.azurerm_dns_zone.customdomain.resource_group_name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.buildagent_aks[each.key].private_service_connection.0.private_ip_address]
}
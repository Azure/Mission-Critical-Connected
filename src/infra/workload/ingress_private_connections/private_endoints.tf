## Build Agent Private Endpoints

### AKS ingress ###
resource "azurerm_private_endpoint" "buildagent_aks" {
  for_each = var.private_link_service_targets

  name                = "${local.prefix}-${each.key}-built-agent-aks-ingress-pe"
  location            = data.azurerm_resource_group.buildagent.location
  resource_group_name = data.azurerm_resource_group.buildagent.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.id}/subnets/private-endpoints-snet"

  private_service_connection {
    name                           = "${local.prefix}-${each.key}-aks-buildagent-ingress-privateserviceconnection"
    private_connection_resource_id = each.value.private_link_service_id
    is_manual_connection           = false
  }

  tags = local.default_tags
}
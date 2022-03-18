resource "azurerm_private_link_service" "aks_ingress" {
  for_each            = var.private_link_service_targets

  name                = "${local.prefix}-${each.key}-aks-ingress-pl"
  resource_group_name = each.value.resource_group_name
  location            = each.key

  auto_approval_subscription_ids              = [data.azurerm_subscription.current.id]
  visibility_subscription_ids                 = [data.azurerm_subscription.current.id]
  load_balancer_frontend_ip_configuration_ids = [each.value.lb_IpConfiguration_Id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address_version = "IPv4"
    subnet_id                  = each.value.subnet_Id
    primary                    = true
  }

  tags = local.default_tags
}
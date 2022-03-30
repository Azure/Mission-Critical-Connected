resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.global.name

  sku_name = "Premium_AzureFrontDoor"

  response_timeout_seconds = 120

  tags = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name      = local.frontdoor_default_frontend_name

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  enabled = true

  tags = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "cname" {

  count = azurerm_dns_cname_record.app_subdomain != "" ? 1 : 0

  name      = local.frontdoor_custom_frontend_name
  #host_name = trimsuffix(frontend_endpoint.value.fqdn, ".")

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  enabled                  = true

  tags = local.default_tags

}
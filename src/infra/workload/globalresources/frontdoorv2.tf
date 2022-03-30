resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.global.name
 
  sku_name = "Premium_AzureFrontDoor"

  origin_response_timeout_seconds = 120

  tags = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name                            = local.frontdoor_default_frontend_name
  cdn_frontdoor_profile_id        = azurerm_cdn_frontdoor_profile.main.id
  enabled                   = false

  tags = local.default_tags
}
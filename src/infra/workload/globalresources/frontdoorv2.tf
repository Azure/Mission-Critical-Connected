resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.global.name

  sku_name = "Premium_AzureFrontDoor"

  response_timeout_seconds = 120

  tags = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name = local.frontdoor_default_frontend_name

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  enabled = true

  tags = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "cname" {

  count = azurerm_dns_cname_record.app_subdomain != "" ? 1 : 0

  name = local.frontdoor_custom_frontend_name
  #host_name = trimsuffix(frontend_endpoint.value.fqdn, ".")

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  enabled                  = true

  tags = local.default_tags

}

resource "azurerm_cdn_frontdoor_origin_group" "backendapis" {
  name = "backendapis"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  session_affinity = false

  health_probe {
    protocol            = "Http"
    request_type        = "GET"
    path                = "/"
    interval_in_seconds = 240
  }

  load_balancing {
    sample_size                        = 6
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 0
  }
}

resource "azurerm_cdn_frontdoor_origin" "backendapi" {

  for_each = var.backends_BackendApis

  name                          = each.value.address
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id
  host_name                     = each.value.address
  weight                        = each.value.weight

}
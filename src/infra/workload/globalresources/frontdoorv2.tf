resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = local.frontdoor_name
  resource_group_name      = azurerm_resource_group.global.name
  response_timeout_seconds = 120

  sku_name = "Premium_AzureFrontDoor"
  tags     = local.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name    = local.frontdoor_default_frontend_name
  enabled = true

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_endpoint" "cname" {
  count = azurerm_dns_cname_record.app_subdomain != "" ? 1 : 0

  name    = local.frontdoor_custom_frontend_name
  enabled = true
  tags    = local.default_tags

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
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

resource "azurerm_cdn_frontdoor_origin_group" "globalstorage" {
  name = "GlobalStorage"

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

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "staticstorage" {
  name = "StaticStorage"

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

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-primary" {
  name      = azurerm_storage_account.global.primary_web_host
  host_name = azurerm_storage_account.global.primary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 1

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-secondary" {
  name      = azurerm_storage_account.global.secondary_web_host
  host_name = azurerm_storage_account.global.secondary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 2

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_origin" "backendapi" {
  for_each = toset(keys({for i, r in var.backends_BackendApis:  i => r}))

  name      = split(var.backends_BackendApis[each.value]["address"], ".")[0]
  host_name = var.backends_BackendApis[each.value]["address"]
  weight    = var.backends_BackendApis[each.value]["weight"]

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id
}

resource "azurerm_cdn_frontdoor_origin" "staticstorage" {
  for_each = toset(keys({for i, r in var.backends_StaticStorage:  i => r}))

  name      = split(var.backends_StaticStorage[each.value]["address"], ".")[0]
  host_name = var.backends_StaticStorage[each.value]["address"]
  weight    = var.backends_StaticStorage[each.value]["weight"]

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id
}

resource "azurerm_cdn_frontdoor_custom_domain" "test" {
  count = var.custom_fqdn != "" ? 1 : 0

  name                     = local.frontdoor_custom_frontend_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  host_name = azurerm_dns_cname_record.app_subdomain

  tls_settings {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}
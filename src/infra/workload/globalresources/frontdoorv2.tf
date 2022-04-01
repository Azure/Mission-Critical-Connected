resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = local.frontdoor_name
  resource_group_name      = azurerm_resource_group.global.name
  response_timeout_seconds = 120

  sku_name = "Premium_AzureFrontDoor"
  tags     = local.default_tags
}

# Default Front Door endpoint
resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name    = local.frontdoor_default_frontend_name
  enabled = true

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Front Door Origin Group used for Backend APIs hosted on AKS
resource "azurerm_cdn_frontdoor_origin_group" "backendapis" {
  name = "BackendAPIs"

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

# Front Door Origin Group used for Global Storage Accounts
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

# Front Door Origin Group used for Static Storage Accounts
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
  name      = "primary"
  host_name = azurerm_storage_account.global.primary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 1

  enable_health_probes = true

  cdn_frontdoor_origin_host_header = azurerm_storage_account.global.primary_web_host
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-secondary" {
  name      = "secondary"
  host_name = azurerm_storage_account.global.secondary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 2

  enable_health_probes = true

  cdn_frontdoor_origin_host_header = azurerm_storage_account.global.secondary_web_host
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_route" "globalstorage" {
  name                          = "GlobalStorage"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id

  patterns_to_match = [
    "/images/*"
  ]

  supported_protocols = [
    "HTTPS"
  ]

  link_to_default_domain = var.custom_fqdn == "" ? true : false # link to default when no custom domain is set

  cdn_frontdoor_origin_ids = [ # this attribute is probably obsolete - commented on github
    azurerm_cdn_frontdoor_origin.globalstorage-primary.id,
    azurerm_cdn_frontdoor_origin.globalstorage-secondary.id
  ]
}

resource "azurerm_cdn_frontdoor_origin" "backendapi" {
  for_each = toset(keys({ for i, r in var.backends_BackendApis : i => r }))

  name      = replace(var.backends_BackendApis[each.value]["address"], ".", "-")
  host_name = var.backends_BackendApis[each.value]["address"]
  weight    = var.backends_BackendApis[each.value]["weight"]

  enable_health_probes = var.backends_BackendApis[each.value]["enabled"]

  cdn_frontdoor_origin_host_header = var.backends_BackendApis[each.value]["address"]
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.backendapis.id
}

resource "azurerm_cdn_frontdoor_route" "backendapi" {
  name                          = "BackendAPI"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapi.id

  patterns_to_match = [
    "/api/*", 
    "/health/*",
    "/swagger/*"
  ]

  supported_protocols = [
    "HTTPS"
  ]

  link_to_default_domain = var.custom_fqdn == "" ? true : false # link to default when no custom domain is set

  cdn_frontdoor_origin_ids = [ # this attribute is probably obsolete - commented on github
    azurerm_cdn_frontdoor_origin.globalstorage-primary.id, # cannot be empty - requires a valid origin resource id
    azurerm_cdn_frontdoor_origin.globalstorage-secondary.id # cannot be empty - requires a valid origin resource id
  ]
}

resource "azurerm_cdn_frontdoor_origin" "staticstorage" {
  for_each = toset(keys({ for i, r in var.backends_StaticStorage : i => r }))

  name      = replace(var.backends_StaticStorage[each.value]["address"], ".", "-")
  host_name = var.backends_StaticStorage[each.value]["address"]
  weight    = var.backends_StaticStorage[each.value]["weight"]

  enable_health_probes = var.backends_StaticStorage[each.value]["enabled"]

  cdn_frontdoor_origin_host_header = var.backends_StaticStorage[each.value]["address"]
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.staticstorage.id
}

resource "azurerm_cdn_frontdoor_route" "staticstorage" {
  name                          = "StaticStorage"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id

  patterns_to_match = [
    "/*"
  ]

  supported_protocols = [
    "HTTPS"
  ]

  link_to_default_domain = var.custom_fqdn == "" ? true : false # link to default when no custom domain is set

  cdn_frontdoor_origin_ids = [ # this attribute is probably obsolete - commented on github
    azurerm_cdn_frontdoor_origin.globalstorage-primary.id, # cannot be empty - requires a valid origin resource id
    azurerm_cdn_frontdoor_origin.globalstorage-secondary.id # cannot be empty - requires a valid origin resource id
  ]
}

#resource "azurerm_cdn_frontdoor_route" "backendapis" {
#  name                          = "BackendAPIs"
#  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
#  enabled                       = true
#  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id
#  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.backendapi.*.id]
#}

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
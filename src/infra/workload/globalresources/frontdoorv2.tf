resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = local.frontdoor_name
  resource_group_name      = azurerm_resource_group.global.name
  response_timeout_seconds = 120

  sku_name = "Premium_AzureFrontDoor"
  tags     = local.default_tags
}

# Default Front Door endpoint
resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name    = "${local.prefix}-primaryendpoint" # needs to be a gloablly unique name
  enabled = true

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_custom_domain" "global" {
  name                     = "CustomDomainFrontendEndpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  host_name   = local.frontdoor_fqdn
  dns_zone_id = data.azurerm_dns_zone.customdomain.id

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# Front Door Origin Group used for Backend APIs hosted on AKS
resource "azurerm_cdn_frontdoor_origin_group" "backendapis" {
  name = "BackendApis"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/health/stamp"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_count                       = 16
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 0
  }
}

# Front Door Origin Group used for Global Storage Accounts
resource "azurerm_cdn_frontdoor_origin_group" "globalstorage" {
  name = "GlobalStorage"

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/images/health.check"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_count                       = 16
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 0
  }

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Front Door Origin Group used for Static Storage Accounts
resource "azurerm_cdn_frontdoor_origin_group" "staticstorage" {
  name = "StaticStorage"

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_count                       = 16
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

  health_probes_enabled          = true
  certificate_name_check_enabled = true

  origin_host_header = azurerm_storage_account.global.primary_web_host

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-secondary" {
  name      = "secondary"
  host_name = azurerm_storage_account.global.secondary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 2

  health_probes_enabled          = true
  certificate_name_check_enabled = true

  origin_host_header = azurerm_storage_account.global.secondary_web_host

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_route" "globalstorage" {
  name                          = "GlobalStorageRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id

  patterns_to_match = [
    "/images/*"
  ]

  supported_protocols = [
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  link_to_default_domain_enabled  = true
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.global.id]

  cdn_frontdoor_origin_ids = [ # this attribute is probably obsolete - commented on github
    azurerm_cdn_frontdoor_origin.globalstorage-primary.id,
    azurerm_cdn_frontdoor_origin.globalstorage-secondary.id
  ]
}

resource "azurerm_cdn_frontdoor_origin" "backendapi" {
  for_each = { for index, backend in var.backends_BackendApis : backend.address => backend }

  name               = replace(each.value.address, ".", "-") # Name must not contain dots, so we use hyphens instead
  host_name          = each.value.address
  origin_host_header = each.value.address
  weight             = each.value.weight

  health_probes_enabled          = each.value.enabled
  certificate_name_check_enabled = true

  dynamic "private_link" {
    for_each = each.value.privatelink_service_id != "" ? [1] : [] # a workaround to make a nested block optional
    content {
      request_message        = "Request access for CDN Frontdoor Private Link Origin for prefix ${local.prefix}"
      location               = each.value.privatelink_location
      private_link_target_id = each.value.privatelink_service_id
    }
  }

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id
}

resource "azurerm_cdn_frontdoor_route" "backendapi" {
  name                          = "BackendApiRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id

  patterns_to_match = [
    "/api/*",
    "/health/*",
    "/swagger/*"
  ]

  supported_protocols = [
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  link_to_default_domain_enabled  = true
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.global.id]

  cdn_frontdoor_origin_ids = [for i, b in azurerm_cdn_frontdoor_origin.backendapi : b.id]
}

resource "azurerm_cdn_frontdoor_origin" "staticstorage" {
  for_each = { for index, backend in var.backends_StaticStorage : backend.address => backend }

  name               = replace(each.value.address, ".", "-")
  host_name          = each.value.address
  origin_host_header = each.value.address
  weight             = each.value.weight

  health_probes_enabled          = each.value.enabled
  certificate_name_check_enabled = true

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id
}

resource "azurerm_cdn_frontdoor_route" "staticstorage" {
  name                          = "StaticStorageRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id

  patterns_to_match = [
    "/*"
  ]

  supported_protocols = [
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  link_to_default_domain_enabled  = true
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.global.id]

  cdn_frontdoor_origin_ids = [for i, b in azurerm_cdn_frontdoor_origin.staticstorage : b.id]
}

# resource "azurerm_cdn_frontdoor_firewall_policy" "global" {
#   name                     = "${local.prefix}globalfdfp"
#   resource_group_name      = azurerm_resource_group.global.name
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#   sku_name                 = "Premium_AzureFrontDoor"
#   enabled                  = true
#   mode                     = "Prevention"

#   managed_rule {
#     type    = "Microsoft_DefaultRuleSet"
#     version = "2.0"
#   }
#   managed_rule {
#     type    = "Microsoft_BotManagerRuleSet"
#     version = "1.0"
#   }
# }
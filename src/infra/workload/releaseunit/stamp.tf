module "stamp" {
  for_each = toset(var.stamps) # for each needs a set, cannot work with a list
  source   = "./modules/stamp"

  location = each.value

  vnet_resource_id = var.vnet_resource_ids[each.value]

  kubernetes_version = var.kubernetes_version # kubernetes version

  prefix       = var.prefix         # handing over the resource prefix
  suffix       = var.suffix         # handing over the resource suffix
  default_tags = local.default_tags # handing over the resource tags
  queued_by    = var.queued_by

  global_resource_group_name     = var.global_resource_group_name
  monitoring_resource_group_name = var.monitoring_resource_group_name
  cosmosdb_account_name          = var.cosmosdb_account_name
  cosmosdb_database_name         = var.cosmosdb_database_name
  global_storage_account_name    = var.global_storage_account_name

  azure_monitor_action_group_resource_id = var.azure_monitor_action_group_resource_id
  frontdoor_id_header                    = var.frontdoor_id_header
  acr_name                               = var.acr_name

  aks_node_size                   = var.aks_node_size
  aks_node_pool_autoscale_minimum = var.aks_node_pool_autoscale_minimum
  aks_node_pool_autoscale_maximum = var.aks_node_pool_autoscale_maximum

  event_hub_thoughput_units         = var.event_hub_thoughput_units
  event_hub_enable_auto_inflate     = var.event_hub_enable_auto_inflate
  event_hub_auto_inflate_maximum_tu = var.event_hub_auto_inflate_maximum_tu

  alerts_enabled       = var.alerts_enabled
  api_key              = random_password.api_key.result
  ai_adaptive_sampling = var.ai_adaptive_sampling
}

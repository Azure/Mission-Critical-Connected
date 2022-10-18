module "stamp" {
  for_each = toset(var.stamps) # for each needs a set, cannot work with a list
  source   = "./modules/stamp"

  location = each.value

  vnet_resource_id = var.vnet_resource_ids[each.value]

  aks_kubernetes_version = var.aks_kubernetes_version # kubernetes version

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
  acr_name                               = var.acr_name

  custom_dns_zone                    = var.custom_dns_zone
  custom_dns_zone_resourcegroup_name = var.custom_dns_zone_resourcegroup_name

  aks_system_node_pool_sku_size          = var.aks_system_node_pool_sku_size
  aks_system_node_pool_autoscale_minimum = var.aks_system_node_pool_autoscale_minimum
  aks_system_node_pool_autoscale_maximum = var.aks_system_node_pool_autoscale_maximum

  aks_user_node_pool_sku_size          = var.aks_user_node_pool_sku_size
  aks_user_node_pool_autoscale_minimum = var.aks_user_node_pool_autoscale_minimum
  aks_user_node_pool_autoscale_maximum = var.aks_user_node_pool_autoscale_maximum

  event_hub_thoughput_units         = var.event_hub_thoughput_units
  event_hub_enable_auto_inflate     = var.event_hub_enable_auto_inflate
  event_hub_auto_inflate_maximum_tu = var.event_hub_auto_inflate_maximum_tu

  alerts_enabled       = var.alerts_enabled
  api_key              = random_password.api_key.result
  ai_adaptive_sampling = var.ai_adaptive_sampling
}

# Variable file for INT env
aks_system_node_pool_sku_size          = "Standard_D2s_v3" # Adjust as needed for your workload
aks_system_node_pool_autoscale_minimum = 2
aks_system_node_pool_autoscale_maximum = 6

aks_user_node_pool_sku_size          = "Standard_F8s_v2" # Adjust as needed for your workload
aks_user_node_pool_autoscale_minimum = 2
aks_user_node_pool_autoscale_maximum = 6

event_hub_thoughput_units     = 1
event_hub_enable_auto_inflate = false

vnet_resource_ids = {
  "westeurope" = "/subscriptions/afffa704-8cbd-46f2-a146-b473f632ecb5/resourceGroups/ao-network/providers/Microsoft.Network/virtualNetworks/vnet-we"
}

ai_adaptive_sampling = true # enables/disables adaptive sampling for Application Insights; disabled means that 100 % of telemetry will be collected
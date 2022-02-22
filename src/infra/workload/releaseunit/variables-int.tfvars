# Variable file for INT env
aks_node_size                   = "Standard_F8s_v2" # be aware of the disk size requirement for emphemral disks. Thus we currently cannot use a smaller SKU
aks_node_pool_autoscale_minimum = 3
aks_node_pool_autoscale_maximum = 6

event_hub_thoughput_units     = 1
event_hub_enable_auto_inflate = false

vnet_resource_ids = {
  "westeurope" = "/subscriptions/afffa704-8cbd-46f2-a146-b473f632ecb5/resourceGroups/ao-network/providers/Microsoft.Network/virtualNetworks/vnet-we"
}
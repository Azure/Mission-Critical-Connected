locals {
  health_blob_name = "stamp.health"

  kql_queries = "${path.root}/../../monitoring/queries/stamp" # directory that contains the kql queries

  # resources in stamp deployments are typically named <prefix>-<locationshort>-<service>
  prefix         = "${lower(var.prefix)}${lower(var.suffix)}" # prefix used for resource naming
  location_short = substr(var.location, 0, 9)                 # shortened location name used for resource naming

  global_resource_prefix = regex("^(.+)-global-rg$", var.global_resource_group_name)[0] # extract global resource prefix from the global resource group name

  vnet_name_and_rg = regex("^.+/(?P<rg>.+)/providers/Microsoft.Network/virtualNetworks/(?P<vnet>.+)$", var.vnet_resource_id)

  vnet_resource_group_name = local.vnet_name_and_rg.rg
  vnet_name                = local.vnet_name_and_rg.vnet
}

output "stamp_properties" {
  value = [for location, v in var.private_link_service_targets : {
    location                         = location
    buildagent_pe_ingress_fqdn       = trimsuffix(azurerm_dns_a_record.build_agent_ingress_private_endpoint[location].fqdn, ".") # remove trailing dot from fqdn
    private_link_service_fqdn        = "internal.ingress.${location}.${local.prefix}.${var.custom_dns_zone}"                     # adding this as convienence output so we can easily use it for Front door input. Same is created by the release unit deployment
    private_link_service_resource_id = v.private_link_service_id                                                                 # adding this as convienence output so we can easily use it for Front door input. Same is created by the release unit deployment
  }]
}

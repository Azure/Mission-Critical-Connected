output "private_link_service_properties" {
  value = tomap({
    for location, inst in var.private_link_service_targets : location => {
      private_link_service_resource_id = azurerm_private_link_service.aks_ingress[location].id
      buildagent_pe_ingress_fqdn       = trimsuffix(azurerm_dns_a_record.build_agent_ingress_private_endpoint[location].fqdn, ".") # remove trailing dot from fqdn
    }
  })
}

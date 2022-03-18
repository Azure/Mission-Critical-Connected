output "private_link_service_resource_ids" {
  value = tomap({
    for location, inst in var.private_link_service_targets : location => {
      private_link_service_resource_id = azurerm_private_link_service.aks_ingress[location].id
    }
  })
}
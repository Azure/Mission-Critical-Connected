output "location" {
  value = var.location
}

output "resource_group_name" {
  value = azurerm_resource_group.stamp.name
}

output "key_vault_name" {
  value = azurerm_key_vault.stamp.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.stamp.id
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.stamp.name
}

output "aks_kubelet_clientid" {
  value = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.client_id
}

# Ingress Controller FQDN (points to private IP address)
output "aks_ingress_fqdn" {
  value = trimsuffix(azurerm_dns_a_record.cluster_ingress.fqdn, ".") # remove trailing dot from fqdn
}

output "aks_internal_lb_ip_address" {
  value = local.aks_internal_lb_ip_address
}

# Name of the subnet in which the private load balancer for the ingress will be created
output "aks_ingress_loadbalancer_subnet_name" {
  value = azurerm_subnet.aks_lb.name
}

# Name of the subnet in which the private link for the ingress will be created
output "aks_ingress_privatelink_subnet_name" {
  value = azurerm_subnet.aks_pl.name
}

output "aks_node_resourcegroup_name" {
  value = azurerm_kubernetes_cluster.stamp.node_resource_group
}

output "public_storage_account_name" {
  value = azurerm_storage_account.public.name
}

# Hostname of the static website storage endpoint
output "public_storage_static_web_host" {
  value = azurerm_storage_account.public.primary_web_host
}

output "app_insights_id" {
  value = data.azurerm_application_insights.stamp.id
}

output "app_insights_name" {
  value = data.azurerm_application_insights.stamp.name
}

output "eventhub_id" {
  value = azurerm_eventhub_namespace.stamp.id
}

# client_id of the catalogservice managed identity
output "catalogservice_managed_identity_client_id" {
  value = azurerm_user_assigned_identity.catalogservice.client_id
}

# client_id of the healthservice managed identity
output "healthservice_managed_identity_client_id" {
  value = azurerm_user_assigned_identity.healthservice.client_id
}

# client_id of the backgroundprocessor managed identity
output "backgroundprocessor_managed_identity_client_id" {
  value = azurerm_user_assigned_identity.backgroundprocessor.client_id
}

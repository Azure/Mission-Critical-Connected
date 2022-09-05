# Permission for AKS to assign the pre-created PIP to its load balancer
# https://docs.microsoft.com/azure/aks/static-ip#create-a-service-using-the-static-ip-address
resource "azurerm_role_assignment" "aks_vnet_contributor" {
  scope                = azurerm_resource_group.stamp.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.stamp.identity.0.principal_id
}

# Permission for AKS to assign the LB in the pre-created VNet
# https://docs.microsoft.com/en-us/azure/aks/internal-lb#use-private-networks
resource "azurerm_role_assignment" "aks_vnet_rg_vnet_contributor" {
  scope                = data.azurerm_virtual_network.stamp.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.stamp.identity.0.principal_id
}

# Permission for AKS to pull images from the globally shared ACR
resource "azurerm_role_assignment" "acrpull_role" {
  scope                = data.azurerm_container_registry.global.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.object_id
}

# DNS Contributor role for AKS kubelet, to be used by cert-manager
resource "azurerm_role_assignment" "dns_contributor" {
  scope                = data.azurerm_dns_zone.customdomain.id
  role_definition_name = "DNS Zone Contributor"
}

# Permission for the kubelet as used by the Health Service to query the regional LA workspace
resource "azurerm_role_assignment" "loganalyticsreader_role" {
  scope                = data.azurerm_log_analytics_workspace.stamp.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.object_id
}

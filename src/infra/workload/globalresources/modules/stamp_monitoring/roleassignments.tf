resource "azurerm_role_assignment" "stamp" {
  count = var.azure_monitor_function_principal_id != "" ? 1 : 0
  scope                = azurerm_log_analytics_workspace.stamp.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.azure_monitor_function_principal_id
}
resource "azurerm_application_insights" "stamp" {
  name                 = "${local.prefix_with_location}-appi"
  location             = var.location
  resource_group_name  = var.resource_group_name
  application_type     = "web"
  workspace_id         = azurerm_log_analytics_workspace.stamp.id
  daily_data_cap_in_gb = 30

  tags = var.default_tags
}

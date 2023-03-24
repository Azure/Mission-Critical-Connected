########### Common variables (same for global resources and for release units) ###########

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}

variable "suffix" {
  description = "A suffix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  default     = ""
}

variable "stamps" {
  description = "List of Azure regions into which stamps are deployed. Important: The first location in this list will be used as the main location for this deployment."
  type        = list(string)
}

variable "branch" {
  description = "Name of the repository branch used for the deployment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "environment" {
  description = "Environment - int, prod or e2e"
  type        = string
}

variable "contact_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "OVERWRITE@noreply.com"
}

variable "alerts_enabled" {
  description = "Enable alerts?"
  type        = bool
  default     = false
}

########### Global Resource specific variables ###########

variable "custom_dns_zone" {
  description = "Custom DNS Zone name. Sample value: int.myapp.net"
  type        = string
}

variable "custom_dns_zone_resourcegroup_name" {
  description = "Resource group which holds the Azure DNS Zone of the custom domain name to be used with this app. Must already be registered and the deploying service principal must have contributor permissions on the DNS zone. Does not need to be supplied if custom_fqdn is empty"
  type        = string
}

variable "front_door_subdomain" {
  description = "Subdomain to be used on Front Door. Sample value: www"
  type        = string
}

variable "cosmosdb_database_name" {
  description = "Name of the globally shared cosmos db database"
  type        = string
  default     = "alwaysondb"
}

variable "cosmosdb_collection_catalogitems_max_autoscale_throughputunits" {
  description = "Number of throughput units that Comsos DB collection can elastically scale out to. Minimum TU value is then 10% of the here set maximum. Must be at least 4000."
  type        = number
  default     = 4000 # 4000 is the minimum possible value
}


variable "cosmosdb_collection_itemcomments_max_autoscale_throughputunits" {
  description = "Number of throughput units that Comsos DB collection can elastically scale out to. Minimum TU value is then 10% of the here set maximum. Must be at least 4000."
  type        = number
  default     = 4000 # 4000 is the minimum possible value
}


variable "cosmosdb_collection_itemratings_max_autoscale_throughputunits" {
  description = "Number of throughput units that Comsos DB collection can elastically scale out to. Minimum TU value is then 10% of the here set maximum. Must be at least 4000."
  type        = number
  default     = 4000 # 4000 is the minimum possible value
}

variable "law_daily_cap_gb" {
  description = "Daily data cap for Log Analytics Workspace and Application Insights in GB"
  type        = number
  default     = 10
}

variable "backends_BackendApis" {
  type = list(object({
    address                = string
    privatelink_service_id = string
    privatelink_location   = string
    weight                 = number
    enabled                = bool
  }))
  default = []
  # sample value = [{
  #   address                = "changeme-api.example.com"
  #   privatelink_service_id = "" # Optional. Example: "/subscriptions/111111111-22222/resourceGroups/sample-rg/providers/Microsoft.Network/privateLinkServices/sample-pl"
  #   privatelink_location   = "" # Optional. Example: "westus2"
  #   weight                 = 1
  #   enabled                = true
  # }]
}

variable "backends_StaticStorage" {
  type = list(object({
    address = string
    weight  = number
    enabled = bool
  }))
  default = []
  # sample value = [{
  #   address = "changeme-storage.example.com"
  #   weight  = 1
  #   enabled = true
  # }]
}

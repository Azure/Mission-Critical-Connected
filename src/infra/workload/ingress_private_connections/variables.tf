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

variable "branch" {
  description = "Name of the repository branch used for the deployment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment. Used as an Azure Resource Tag."
  type        = string
  default     = "n/a"
}

variable "environment" {
  description = "Environment - int, prod or e2e"
  type        = string
  default     = "int"
}

variable "contact_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "OVERWRITE@noreply.com"
}

########### Release Unit specific variables ###########

variable "private_link_service_targets" {
  description = "Map of resource IDs for which to create the Private Link service per stamp (key: stamp, value: object with resource IDs for the load balancer IP config and the subnet)"
  type = map(object({
    resource_group_name   = string # resource group name of the stamp
    lb_IpConfiguration_Id = string # resource ID of the "kubernetes-internal" load balancer IP config
    subnet_Id             = string # Subnet ID in which the load balancer is placed
  }))
}

variable "custom_dns_zone" {
  description = "Custom DNS Zone name"
  type        = string
}

variable "custom_dns_zone_resourcegroup_name" {
  description = "Resource Group Name of the Custom DNS Zone"
  type        = string
}

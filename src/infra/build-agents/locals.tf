locals {
  default_tags = {
    Owner       = "AlwaysOn V-Team"
    Project     = "AlwaysOn Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = "alwaysonappnet@microsoft.com"
    Environment = var.environment
    Prefix      = local.prefix
  }

  prefix = "${lower(var.prefix)}${lower(var.suffix)}-buildagents"
}

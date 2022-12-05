locals {

  default_tags = {
    Owner       = "AlwaysOn V-Team"
    Project     = "AlwaysOn Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = var.contact_email
    Environment = var.environment
    Prefix      = local.prefix
    Branch      = var.branch
  }

  prefix = "${lower(var.prefix)}${lower(var.suffix)}"
}

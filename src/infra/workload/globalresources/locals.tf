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

  location = var.stamps[0] # we use the first location in the list of stamps as the "main" location to root our global resources in, which need it. E.g. Cosmos DB

  frontdoor_name = "${local.prefix}-global-fd"
  frontdoor_fqdn = trimsuffix(azurerm_dns_cname_record.afd_subdomain.fqdn, ".") # remove trailing dot from fqdn

  kql_queries = "${path.root}/../../monitoring/queries/global" # directory that contains the kql queries

  prefix = "${lower(var.prefix)}${lower(var.suffix)}"
}

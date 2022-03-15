# Integrating APIM with Azure Mission-Critical-Connected 
The following guide will help you integrate APIM with the current Azure Mission-Critical-Connected framework to route traffic to your AKS cluster from Front Door. The implementation is broken into three stages: [establishing Front Door to APIM connectivity](#establishing-front-door-to-apim-connectivity), [changing the ingress controller from a public to an internal load balancer](#change-ingress-controller-from-public-to-internal-load-balancer), and [implementing dynamic generation of api definitions in the deployment pipeline](#implement-dynamic-generation-of-api-definitions-in-deployment-pipeline).

## Establishing Front Door to APIM Connectivity
See [this branch](https://github.com/Azure/Mission-Critical-Connected/tree/feature/apim) for implementation or follow the steps below.

1. Copy the [Terraform template](/docs/example-code/apim.tf) for APIM into your [stamp resources folder](/src/infra/workload/releaseunit/modules/stamp/) 
2. Change `publisher_name` and `publisher_email` to the name of your company and an email. Checks any references to resource groups, names, etc. that may be defined outside your APIM definition. 
3. Create a folder called "apim" in the [release unit folder](/src/infra/workload/releaseunit/) and add the 3 files in [example-code](/docs/example-code/) to your branch. These three files are the api definitions for the catalog and health service as well as the apim policy. 
4. To connect Front Door to APIM, we need the value of the APIM FQDN to point Front Door to. In the [outputs.tf file](/src/infra/workload/releaseunit/modules/stamp/outputs.tf), add an output for the APIM FQDN with the following code:
    ```
        # APIM Public FQDN
        output "apim_fqdn" {
        value = replace(azurerm_api_management.alwayson.gateway_url, "https://", "")
        }
    ```
5. Next, we need to define variables for the APIM Public IP and the APIM FQDN. Add the following lines to the [outputs file for a release unit](/src/infra/workload/releaseunit/outputs.tf):
    ```
        apim_fqdn                      = instance.apim_fqdn
        apim_public_ip                 = instance.apim_public_ip
    ```
6. Next, we need to create a subnet for our APIM instance within each stamp. 
    Go to the [stamp network setup file](/src/infra/workload/releaseunit/modules/stamp/network.tf):

    Add a new subnet address under the `subnet_addrs` block for APIM.
    ```
        {
        name     = "apim"
        new_bits = 27 - local.netmask # For the private endpoints we want a /27 sized subnet. So we calculate based on the provided input address space
        }
    ``` 
    Add a new network security group association and subnet for APIM using the code shown below.

    ```
        # Subnet for private endpoints
        resource "azurerm_subnet" "apim" {
        name                 = "apim-snet"
        resource_group_name  = local.vnet_resource_group_name
        virtual_network_name = data.azurerm_virtual_network.stamp.name
        address_prefixes     = [module.subnet_addrs.network_cidr_blocks["apim"]]

        enforce_private_link_endpoint_network_policies = true
        }

        # NSG - Assign default nsg to private-endpoints-snet subnet
        resource "azurerm_subnet_network_security_group_association" "apim_default_nsg" {
        subnet_id                 = azurerm_subnet.apim.id
        network_security_group_id = azurerm_network_security_group.default.id
        }
    ```
7. Now we need to point Front Door to the APIM instance instead of the ingress controller. Change `stamp.aks_cluster_ingress_fqdn` to `stamp.apim_fqdn` in the following places: [jobs-init-sampledata.yaml](/.ado/pipelines/templates/jobs-init-sampledata.yaml), [steps-frontdoor-traffic-switch.yaml](/.ado/pipelines/templates/steps-frontdoor-traffic-switch.yaml) and [SmokeTest.ps1](/.ado/scripts/SmokeTest.ps1)
8. Test the implementation by running the deployment pipeline.

## Change Ingress Controller from Public to Internal Load Balancer

## Implement Dynamic Generation of API Definitions in Deployment Pipeline
The current implementation of APIM uses static api definitions that have been created prior to deployment. We want to enable dynamic generation those apis in order to catch configuration or environmental changes without having to update the file. 

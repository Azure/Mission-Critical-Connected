# Self-hosted agent pools with Azure DevOps

This part of the repository contains the required Bicep template to deploy the infrastructure used for self-hosted Azure DevOps build agent pools, based on Virtual Machine Scale Sets (VMSS).

Furthermore, it deploys a VMSS which is used as Jump Servers to connect to the private resources, such as private AKS clusters, for debugging etc. To connect to the Jump Servers, Azure Bastion is used. This way, even the Jump Servers do not require any public IPs.

To deploy the infrastructure for the self-hosted Agents and all supporting services such as Jump Servers and private DNS zones, a ready-to-use Bicep template plus the corresponding ADO Pipeline is included in this repository. Bicep is being used for this part of the infrastructure instead of Terraform, because using Terraform could create a "chicken-and-egg" problem with the state storage account which requires public access. All further resources are then created using Terraform.

## Infrastructure components

The Bicep templates deploys the following infrastructure components:

### VNet

A virtual network, which is not peering to any other network and contains three subnets:

- `buildagents-snet`: Subnet for the build agents
- `jumpservers-snet`: Subnet for the Jump Servers
- `private-endpoints-snet`: Subnet for the private endpoints resources
- `AzureBastionSubnet`: Subnet for Azure Bastion service

Each subnet is assigned a simple Network Security Group (NSG) which basically prohibits any outside access, except for the Bastion service.

### Private DNS Zones

A number of private DNS zones are deployed and linked to the VNet. No Private Endpoints are deployed at this point. This happens as part of the workload deployments at a later point in time. But these Private Endpoints will then make use of the pre-provisioned private DNS zones.

- `privatelink.blob.core.windows.net`: Blob storage data plane
- `privatelink.table.core.windows.net`: Table storage data plane
- `azmk8s.io`: Private AKS cluster control plane
- `privatelink.vaultcore.azure.net`: Key Vault data plane
- `privatelink.azurecr.io`: Azure Container Registry data plane

Additional private DNS zones can be added as needed by the workload that is to be deployed. Generally, any time the workload deployment requires data plane access to one of the services (or control plane access in case of AKS), a Private Endpoint needs to created for that service. Thus, also a private DNS zone needs to exist for the Build Agents.

### VM Scale Sets

Two VM Scale Sets are deployed:

- `buildagents-vmss`: Scale Set for the build agents. These are to be connected to and controlled by [Azure DevOps as a VMSS build agent pool](https://docs.microsoft.com/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops). ADO will scale this VMSS up and down as needed.
- `jumpservers-vmss`: These are jump servers which users can manually connect to via Azure Bastion to then connect to the private resources. For instance, to execute Kubernetes commands using `kubectl`, the jump servers are required. This scale set is initially deployed with 1 instance of a B2s VM. It can be manually scaled up and down as needed. Connection to the jump servers happen via SSH.

#### Configuration

The VMs in the scale sets are provisioned using a standard Ubuntu 20.04 image. In order to install required software for the build and deployment tasks, as well as for manual operations through the jump servers, [`cloud-init`](https://docs.microsoft.com/azure/virtual-machines/linux/using-cloud-init) is used. The [`cloudinit.conf`](./cloudinit.conf) file specifies which packages to install at startup. This way, any time a VM is freshly provisioned, it is based on the latest base image and has all required software in their latest versions installed.

### Azure Bastion Service

The [Bastion service](https://docs.microsoft.com/azure/bastion/bastion-overview) is used to securely connect to the jump servers. This way, the jump servers themselves do not need to expose any public IPs.

---

[Back to documentation root](/docs/README.md)

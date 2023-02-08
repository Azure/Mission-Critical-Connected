# Getting started with Private Build Agents

This guide walks you through the required steps to deploy the Azure Mission-Critical connected reference implementation. The connected version assumes connectivity to other company resources, typically achieved through VNet peering in a hub-and-spoke model (and optionally to on-prem resources using Express Route or VPN). Also, it locks down all traffic to the deployed Azure services to come in through Private Endpoints only. Only the actual user traffic is still flowing in through the public ingress point of [Azure Front Door](https://azure.microsoft.com/services/frontdoor/#overview).

This deployment mode provides even tighter security but requires the use of self-hosted, VNet-integrated Build Agents. Also, for any debugging etc. users must connect through Azure Bastion and Jump Servers which can have an impact on developer productivity. **Be aware of these impacts before deciding to deploy Azure Mission-Critical in connected mode.**

![Azure Mission-Critical Connected Architecture](/docs/media/mission-critical-architecture-connected.svg)

## Overview

On a high level, the following steps will be executed:

1. Import Azure DevOps pipeline which deploys the infrastructure for the self-hosted Build Agents
1. Run the new pipeline to deploy the Virtual Machine Scale Sets for the Build Agents as well as Jump Servers and other supporting resources
1. Configure the self-hosted Build Agents in Azure DevOps
1. Set required variables in the variables files to reference the self-hosted Build Agent resources to later be able to create Private Endpoints

## Import pipeline to deploy self-hosted Build Agents

To deploy the infrastructure for the self-hosted Agents and all supporting services such as Jump Servers and private DNS zones, a ready-to-use Bicep template plus the corresponding ADO Pipeline is included in this repository. Bicep is being used for this part of the infrastructure instead of Terraform, because using Terraform could create a "chicken-and-egg" problem with the state storage account which requires public access. All further resources are then created using Terraform.

> The following steps assume that you have already followed the general [Getting Started guide](/docs/reference-implementation/Getting-Started.md). If you have not done so yet, please go there first.

1. The ADO pipeline definition resides together with the other pipelines in `/.ado/pipelines`. It is called `azure-deploy-private-build-agents.yaml`. Start by importing this pipeline in Azure DevOps.

    ```powershell
    # set the org/project context
    az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

    # import a YAML pipeline
    az pipelines create --name "Azure.AlwaysOn Deploy Build Agents" --description "Azure.AlwaysOn Build Agents" `
                        --branch main --repository https://github.com/<your-fork>/ --repository-type github `
                        --skip-first-run true --yaml-path "/.ado/pipelines/azure-deploy-private-build-agents.yaml"
    ```

    > You'll find more information, including screenshots on how to import and manage YAML-based pipelines in the overall [Getting Started Guide](./Getting-Started.md).

1. If you already know that you have special requirements regarding the software that needs to be present on the Build Agents to build your application code, go modify the [`/src/infra/build-agents/cloudinit.conf`](/src/infra/build-agents/cloudinit.conf)

    > Please note that our self-hosted agents **do not** include the same [pre-installed software](https://learn.microsoft.com/azure/devops/pipelines/agents/hosted) as the Microsoft-hosted agents. Also, our Build Agents are only deployed as Linux VMs. You can technically change to Windows agents, but this is out of scope for this guide.


## Create Azure DevOps Variable group

Before we can deploy the private build agent infrastructure, we need to create a variable group in Azure DevOps which will contain one entry for the Build Agent and Jump Server login password.

## Variable Groups

In addition to the configuration files, there are *variable groups* per environment in Azure DevOps.

The variable groups in Azure DevOps only contain sensitive (secret) values, which must not be stored in code in the repo. They are named `[env]-env-vg` (e.g. prod-env-vg).

In your Azure DevOps project, navigate to **Pipelines** --> **Library** --> **Variable Groups**

Create a new variable group, called `[env]-env-vg` (e.g. e2e-env-vg). Add the variable, as described in the table below.

| Key | Description | Sample value |
| --- | --- | --- |
| buildAgentAdminPassword | Password for the build agents and jump servers. The username is set in the Bicep template. | ******** (mark as secret) |

![variable group](/docs/media/ado_variablegroup.png)

## Deploy self-hosted Build Agent infrastructure

Now that the pipeline for the self-hosted Agent infrastructure is imported and the settings adjusted, we are ready to deploy it. Note that this is done using the Microsoft-hosted agents. We have no requirement here yet for a self-hosted agent (plus, it would create a chicken-and-egg problem anyway).

1. Run the previously imported pipeline. Make sure to select the right branch. Select `e2e` as the environment. You can repeat the same steps later for `int` and `prod` when you are ready to use them.

    ![Run pipeline with environment selector](/docs/media/run-pipeline-with-environment-selector.png)

1. Wait until the pipeline is finished before you continue.

1. Go through the Azure Portal to your newly created Resource Group (something like `ace2e-buildinfra-rg`) to see all the resources that were provisioned for you.

    ![self-hosted agent resources in azure](/docs/media/self-hosted-agents-resources-in-azure.png)


## Configure self-hosted Build Agents in ADO

Next step is to configure our newly created Virtual Machine Scale Set (VMSS) as a self-hosted Build Agent pool in Azure DevOps. ADO will from there on control most operations on that VMSS, like scaling up and down the number of instances.

1. In Azure DevOps navigate to your project settings
1. Go to `Agent pools`
1. Add a pool and select as Pool type `Azure virtual machine scale set`
1. Select your `e2e` Service Connection and locate the VMSS.

    > **Important!** Make sure to select the scale set which ends on `-buildagents-vmss`, not the one for the Jump Servers!

1. Set the name of the pool to **`e2e-private-agents`** (adjust this when you create pools for other environments like `int`)
1. Check the option `Automatically tear down virtual machines after every use`. This ensures that every build run executes on a fresh VM without any leftovers from previous runs
1. Set the minimum and maximum number of agents based on your requirements. We recommend to start with `Number of agents to keep on standby` of `0` and a `Maximum number of VMs in the scale set` of `6`. This means that ADO will scale the VMSS down to 0 if no jobs are running to minimize costs.
1. Click Create

    ![Self-hosted Agent Pool in ADO](/docs/media/self-hosted-agents-pool-in-ado.png)

    > Setting the minimum to `0` saves money by starting build agents on demand, but can slow down the deployment process.

## Deploy Azure Mission-Critical Connected

Now everything is in place to deploy the connected version of Azure Mission-Critical.

Go back to the [Getting Started guide](./Getting-Started.md) and follow the remaining steps to deploy the connected version of Azure Mission-Critical.

## Use Jump Servers to access the deployment

In order to access the now locked-down services like AKS or Key Vault, you can use the Jump Servers which were provisioned as part of the self-hosted Build Agent deployment.

1. Navigate to the Jump Server VMSS in the same resource group. E.g. `aoe2ebuildagents-jumpservers-vmss`, open the Instances blade and select one of the instances (there is probably only one)
    ![Jump Server instances](/docs/media/private_build_agent_jumpservers_instances.png)
1. Select the Bastion blade, enter `alwayson` as username and the password that you set earlier in the variable group. Click Connect.
1. You now have established an SSH connection via Bastion to the Jump Server which has a direct line of sight to your private resources.
    ![SSH jump server](/docs/media/private_build_agent_jumpserver_ssh.png)
1. Use for example `az login` and `kubectl` to connect to and debug your resources.

---

[Back to documentation root](/docs/README.md)

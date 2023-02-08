# Getting started

This step-by-step guide describes the process to deploy the Azure Mission-Critical reference implementation in your own environment from the beginning. At the end of this guide you will have an Azure DevOps organization and project set up to deploy a copy of the Azure Mission-Critical reference implementation into an Azure Subscription.

**This guide describes the steps to get started using the Azure CLI only. To create the set up through the Portal (UI) follow [this guide](./Getting-Started.md) instead.**

## How to deploy?

The Azure Mission-Critical project is using a GitHub repository for version control of code artifacts and manifest files. The project leverages Azure DevOps Pipelines for build and deployment (CI/CD) pipelines.

> Instead of GitHub also other Git-based repositories can be used, such as *Azure DevOps Repos*.

All relevant code artifacts and manifest files are stored in this GitHub repository and can easily be forked into your own account or organization.

This guide describes the end-to-end process for setting up all pre-requisites and dependencies before deploying the Azure Mission-Critical reference implementation into an Azure subscription of your choice.

## Prerequisites

The Azure Mission-Critical reference implementation gets deployed into an Azure Subscription. For this you will need a **Service Principal (SPN) with Owner permissions on that subscription.**

- Either your user needs to have **Owner** or **User Access Administrator (UAA)** permission and you have **the right to create new Service Principals** on your Azure AD tenant, or
- You need to have a pre-provisioned Service Principal with Owner permissions on the subscription

The following must be installed on the client machine used to deploy the Azure Mission-Critical reference implementation:

- [Azure CLI](https://learn.microsoft.com/cli/azure/service-page/azure%20cli?view=azure-cli-latest)
- [Azure DevOps CLI](https://learn.microsoft.com/azure/devops/cli/?view=azure-devops)
- [PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1) (on Windows, Linux or macOS)

Also, to deploy the Connected reference implementation, you are required to have an existing **domain name** which is managed in an Azure DNS Zone. This is needed in order to connect Azure Front Door via Private Link to the backends on AKS, as this requires officially validated SSL certificates. The pipeline will take care of the certificate creation and validation using Let's Encrypt, but you need to provision the DNS Zone beforehand. Depending on your scenario, [Azure App Service Domains](https://learn.microsoft.com/azure/app-service/manage-custom-dns-buy-domain) might be an option to easily procure a domain name.

## Overview

The process to deploy the Azure Mission-Critical reference implementation is comprised of the following steps:

1) Create an [Azure DevOps organization and project](#create-a-new-azure-devops-project)
1) Generate your own repository based on the [Azure Mission-Critical GitHub template](https://github.com/Azure/Mission-Critical-Online/generate) repository
1) Import [deployment pipelines](#3-import-deployment-pipelines)
1) Create [Service Principals](#4-create-azure-service-principal) for each individual Azure subscription
1) Create [Service Connections](#5-create-azure-service-connections) in Azure DevOps
1) [Adjust configuration](#6-adjust-configuration)
1) [Configure pre-provided VNets](#7-configure-pre-provided-vnets-optional)
1) [Set up private build agents](#8-set-up-private-build-agents)
1) [Execute the first deployment](#9-execute-the-first-deployment)
1) [Check deployed resources](#10-check-deployed-resources)

> If you run into any issues during the deployment, consult the [Troubleshooting guide](./Troubleshooting.md).

### 1) Create a new Azure DevOps organization and project

To deploy the Azure Mission-Critical reference implementation, you need to create a new Azure DevOps organization, or re-use an existing one. In this organization you will then create a new project used to host all pipelines for Azure Mission-Critical.

- [Create an organization or project collection](https://learn.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops)

> **Important!** The [Azure DevOps CLI](https://learn.microsoft.com/azure/devops/cli/?view=azure-devops) is used for the subsequent steps. Please make sure that it is installed. The authentication is done via a Personal Access Token (PAT). This can be done via `az devops login` or by storing the PAT token in the `AZURE_DEVOPS_EXT_PAT` environment variable. The token is expected to have at least the following scopes: `Agent Pools`: Read & manage, `Build`: Read & execute, `Project and Team`: Read, write, & manage, `Service Connections`: Read, query, & manage.

Make sure that [Azure DevOps CLI](https://learn.microsoft.com/azure/devops/cli/?view=azure-devops) is configured to use the Azure DevOps organization that was created in the previous task.

```powershell
$env:AZURE_DEVOPS_EXT_PAT="<azure-devops-personal-access-token>"

# set the org context
az devops configure --defaults organization=https://dev.azure.com/<your-org>

# create a new project
az devops project create --name <your-project>
```

> `AZURE_DEVOPS_EXT_PAT` is used for automation purposes. If not set, `az devops login` will prompt you for the Personal Access Token (PAT).

This will result in a new project, `<your-project>` in your Azure DevOps organization:

![New ADO Project](/docs/media/AlwaysOnGettingStarted1.png)

For all the subsequent tasks done via `az devops` or `az pipelines` the context can be set via:

```powershell
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>
```

### 2) Generate your own repository based on the Azure Mission-Critical GitHub template

Azure DevOps Repos would allow us to import the Azure Mission-Critical GitHub repository into Azure DevOps as well. For this guide we have decided to generate our own repository based on the template on GitHub and use it from there.

Go to the root of [this Azure Mission-Critical repository](https://github.com/Azure/Mission-Critical-Connected) on GitHub and click on "Use this template" in the top right corner:

![Use GitHub Repo template](/docs/media/AlwaysOnGettingStarted2Fork.png)

This will let you create a repository in your own account or organization. This is needed to allow you to make modification to our code within your own repository.

### 3) Import deployment pipelines

Now that you have your own repo, let's start to import the pre-created pipelines into Azure Pipelines.

> **You will need to import each Pipeline YAML file individually. But we will only import the E2E pipeline to start with.**

The files to import are the YAML files stored in the root of the `/.ado/pipelines/` directory. **Do not** import files from subdirectories, such as `/.ado/pipelines/config/` or `/.ado/pipelines/templates/`, or from other directories in the repo.

You can find more details about any of the pipelines within the [pipelines documentation](/.ado/pipelines/README.md).

To start, you will import **only** the following pipeline from the `/.ado/pipelines/` directory:

- `/.ado/pipelines/azure-release-e2e.yaml`

When you are later ready to also deploy further environments such as INT (integration) and PROD (production), repeat the same steps (and consecutive actions below) for the respective  pipelines:

- `/.ado/pipelines/azure-release-int.yaml`
- `/.ado/pipelines/azure-release-prod.yaml`

Using the `az devops` / `az pipelines` CLI:

> Note: If you are using Azure DevOps Repos instead of GitHub, change `--repository-type github` to `--repository-type tfsgit` in the command below. Also, if your branch is not called `main` but, for example, `master` change this accordingly.

First, you need to create a PAT (personal access token) on GitHub to use with ADO. This is required to be able to import the pipelines. For this, create a new token [here](https://github.com/settings/tokens). Select `repo` as the scope.

Save the token securely. Then, set it as an environment variable in your shell:

```powershell
$env:AZURE_DEVOPS_EXT_GITHUB_PAT=<your PAT>
```

Now your session is authenticated and the ADO CLI will be able to import the pipelines from GitHub.

```powershell
# set the org/project context
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

# import a YAML pipeline
az pipelines create --name "Azure.AlwaysOn E2E Release" --description "Azure.AlwaysOn E2E Release" `
                    --branch main --repository https://github.com/<your-template>/ --repository-type github `
                    --skip-first-run true --yaml-path "/.ado/pipelines/azure-release-e2e.yaml"
```

### 4) Create Azure Service Principal

> This step can be skipped if a Service Principal was pre-provisioned.

All pipelines require an Azure DevOps service connection to access the target Azure Subscription where the resources are deployed. These service connections use Service Principals to access Azure which can be configured automatically, when proper access is given, or manually in Azure DevOps by providing a pre-created Azure Service Principal with the required permissions.

We need to create an AAD Service Principal with **Subscription-level Owner permissions**. We need owner permission as the pipeline will need to create various role assignments.

You need to repeat these steps for each of the environments that you want to create. But you can also only start with one for now. If so, we recommend to start with `e2e`.

```powershell
# Get the subscription ID
az account show --query id -o tsv

# Output:
xxx-xxxxxxx-xxxxxxx-xxxx

# Verify that this is indeed the subscription you want to target. Otherwise you can switch the scope using:
# az account set --subscription <name>

# Make sure to change the name to a unique one within your tenant
az ad sp create-for-rbac --scopes "/subscriptions/xxx-xxxxxxx-xxxxxxx-xxxx" --role "Owner" --name <CHANGE-MY-NAME-alwayson-deployment-sp>

# Output:
{
  "appId": "d37d23d3-d3d3-460b-a4ab-aa7a11504e76",
  "displayName": "my-alwayson-deployment-sp",
  "password": "notARealP@assword-h3re",
  "tenant": "64f988bf-86f1-42af-91ab-2d7gh011db47"
}
```

Take a note of the `appId` and `password` from the output of that command as you will need it below.

More information about the required permissions needed to deploy via Terraform can be found [here](/src/infra/workload/README.md).

### 5) Create Azure Service Connections

Our Azure Mission-Critical reference implementation knows three different environments: prod, int and e2e. These three environments can be selected for each individual pipeline run and can refer to the same or different (recommended) Azure subscriptions for proper separation. These environments are represented by service connections in Azure DevOps:

> **Important!** Since these connection names are used in pipelines, use them exactly as specified below. If you change the name of the service connection, you have to also change it in pipeline YAML.

- `alwayson-e2e-serviceconnection`
- `alwayson-prod-serviceconnection`
- `alwayson-int-serviceconnection`

> If you only created one Service Principal above, you only need to create one Service Connection for now.

Make sure that you specify the right credentials for the **service principal created earlier**.

```powershell
# set the org/project context
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="<service-principal-password>"

# create a new service connection
az devops service-endpoint azurerm create `
    --name alwayson-e2e-serviceconnection `
    --azure-rm-tenant-id <tenant-id> `
    --azure-rm-service-principal-id <app-id> `
    --azure-rm-subscription-id <subscription-id> `
    --azure-rm-subscription-name <subscription-name>
```

> `AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY` is used for automation purposes. If not set, `az devops` will prompt you for the service principal password. See [az devops service-endpoint azurerm](https://learn.microsoft.com/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest) for more information about parameters and options.

### 6) Adjust configuration

There are three variables files in the `/.ado/pipelines/config` folder, one for each environment. You need to edit these files to reflect your own workspace before you execute the first deployments. They are named `variables-values-[env].yaml`.

Modify the respective file for the environment which you want to deploy. At least the variables which are marked as `required` in the table below need to be changed.

| Required to modify | Key | Description | Sample value |
| --- | --- | --- | --- |
| **YES** | prefix | Custom prefix used for Azure resources. **Must not be longer than 6 characters!** | mye2e |
| **YES** | contactEmail | E-mail alias used for alerting. **Be careful which address you put in here as it will potentially receive a lot of notification emails** | alwaysonappnet@example.com |
| NO | terraformResourceGroup | Resource Group where the Terraform state Storage account will be deployed | terraformstate-rg |
| NO | stampLocations | List of locations (Azure Regions) where this environment will be deployed into. You can keep the default to start with.  | ["northeurope", "eastus2"] |
| **YES** | envDnsZoneRG | Name of the Azure Resource group which holds the Azure DNS Zone for your custom domain. | mydns-rg |
| **YES** | envDomainName | Name of the Azure DNS Zone. | example.com |

**After modifying the file, make sure to commit and push the changes to your Git repository.**

For more details on the variables, you can consult [this guide](/.ado/pipelines/README.md#configuration-files).

### 7) Configure pre-provided VNets (optional)

If you are deploying an environment, which needs connectivity to other company resources such as through a hub-and-spoke model, you need to pre-provision a number of VNets for this environment. If you do not plan to use this feature for the environment which you are working on right now (e.g. E2E), you can skip this step. In this case, the deployment will create temporary, unconnected VNets for each deployment.

For every region that you want to deploy stamps into, you need at least two pre-provisioned VNets. Those will often be created by a central platform team with peering set up to a hub network. These VNets need to be created in the same subscription as the environment. Collect the resource IDs of the VNets and create/update the corresponding file in `.ado/pipelines/config/vnets-[environment].json`. See [`/.ado/pipelines/config/vnets-int.json`](/.ado/pipelines/config/vnets-int.json) for an example.

See [this guide](/src/infra/README.md#networking) for more information about the VNet usage and setup.

**After modifying the file, make sure to commit and push the changes to your Git repository.**

### 8) Set up private build agents

In order to deploy the resources in the next step, you must first set up the private Build Agent infrastructure. For detailed instructions on this, please follow [this guide](./Private-Agents-Setup.md).

### 9) Execute the first deployment

After completing all previous steps in this guide, you can start executing the pipelines to spin up the infrastructure.

You might notice a longer delay until the job actually starts. This is due to the fact the ADO first needs to spin up instances in the scale set before they can pick up any task.

Otherwise you should see no immediate difference compared to the [Azure Mission-Critical Online](https://github.com/Azure/Mission-Critical-Online) reference implementation in the deployment itself. However, when you check the deployed resources, you will notice differences. For example that AKS is now deployed as a private cluster or that you will not be able to see the repositories in the Azure Container Registry through the Azure Portal anymore (due to the network restrictions to only allow Private Endpoint traffic).

Go the the **Pipelines** section of the Azure DevOps Portal and click on the E2E release pipeline.

Then click **Run pipeline**:

![Run pipeline](/docs/media/devops_e2e_pipeline_header.png 'Run pipeline')

In the popup window, **uncheck** the box **Destroy environment at the end** and then click **Run**.

![Start pipeline](/docs/media/devops_run_e2e_pipeline.png 'Start E2E pipeline run')

This will now kick off your first full pipeline run. You can follow the progress in the run screen:

![Pipeline run overview](/docs/media/devops_e2e_pipeline_run_screen.png)

Upon the first execution of a pipeline, Azure DevOps might ask you to grant permissions on the required service connection to Azure, as well as the environment.

![Pipeline permission](/docs/media/AlwaysOnGettingStarted2PipelinePermission.png)

Click on **View** and then on **Permit** for each required permission.

![Pipeline permission](/docs/media/AlwaysOnGettingStarted2PipelinePermissionGrant.png)

After this, the pipeline execution will kick off.

> If you run into any issues during the deployment, consult the [Troubleshooting guide](./Troubleshooting.md).

The full run, which deploys all resources from scratch, might take around 30-40 minutes. Once all jobs are finished, **take a note of the resource prefix** which is now shown in the header of your pipeline screen:

![Resource tag](/docs/media/e2e_pipeline_prefix_tag.png)

### 10) Check deployed resources

You can now go to the Azure Portal and check the provisioned resources. In the Resource Groups blade, locate the groups which start with the aforementioned prefix. You will see two resources groups (or more, depending if you changed the number of desired stamps):

![Azure Resource Groups](/docs/media/e2e_azure_resource_groups.png)

**Global Resources**
![Azure Global Resources](/docs/media/e2e_azure_resources_global.png)

**Stamp Resources**
![Azure Stamp Resources](/docs/media/e2e_azure_resources_stamp.png)

For information on how to connect to the data plane, e.g. of AKS follow [this guide](/src/infra/build-agents/README.md#use-jump-server-via-bastion).

#### Browse to the demo app website

We can now browse to the demo app website. Fetch the URL from the Front Door resource:

1) Find the "Global Resource" group, e.g. `<myprefix>123-global-fd`
1) Click on the Front Door resource (e.g. `<myprefix>123-global-fd`)
1) Click on the "Frontend host" link
![Frontend host](/docs/media/frontdoor-resource-hostlink.png)
1) This opens the landing page of the demo app. Feel free to browse around!

![landingpage](/docs/media/website_landingpage.png)

![catalogpage](/docs/media/website_catalogpage.png)

## Additional information to learn more

With the completion of at least one deployment pipeline it is now a good time to read more about the pipeline workflows and other available documentation:

- Guidance on [Azure DevOps Workflows](/.ado/pipelines/README.md)

- Detailed information about the infrastructure layer - [Terraform documentation](/src/infra/workload/README.md#get-started).

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)

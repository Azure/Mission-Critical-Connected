# Developer Guide

## Tools Required

The following tools and applications should be installed on the client machine used to effectively develop or deploy the Azure Mission-Critical reference implementation:

- Install [Azure CLI](https://docs.microsoft.com/cli/azure/service-page/azure%20cli?view=azure-cli-latest)

- Install [Azure DevOps CLI](https://docs.microsoft.com/azure/devops/cli/?view=azure-devops)

- Install [PowerShell](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1).

- Install [Visual Studio Code](https://code.visualstudio.com/Download)

- Install [Terraform CLI](https://www.terraform.io/downloads)

## Structure of the Azure Mission-Critical reference implementation

All infrastructure code lives in the [workload folder](/src/infra/workload/), where they are separated by [global](/src/infra/workload/globalresources/) and [releaseunit](/src/infra/workload/releaseunit/). Each service has a .tf file (Terraform Template) that contains its definition and configuration. If you need to make a change to the definition or configuration of a service, you will need to locate its .tf file. 


### Example

You want to turn off zone redundancy for Cosmos DB. Go to [cosmosdb.tf](/src/infra/workload/globalresources/cosmosdb.tf) and change the `zone_redundant` field to false under `geo-location` 

`dynamic "geo_location" {
    for_each = var.stamps
    content {
      location          = geo_location.value
      failover_priority = geo_location.key
      zone_redundant    = true --> **false**
    }
  }`

  If you want to make an addition to a service such as adding an additional database to Cosmos DB, you will need to locate all files that interact with the service.
  
  ### Example

  You want to add another database to Cosmos DB for Inventory. You need to instantiate another database in the cosmosdb.tf and edit all the files that contain variables or variable references for database names.

  1. Go to the [global variables file](/src/infra/workload/globalresources/variables.tf). Copy and paste lines 67-71. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  2. Go to the [stamp variables file](/src/infra/workload/releaseunit/modules/stamp/variables.tf). Copy and paste lines 51-54. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  3. Go to the [release unit variables file](/src/infra/workload/releaseunit/variables.tf). Copy and paste lines 75-78. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  4. Go to the [stamp definition file](/src/infra/workload/releaseunit/stamp.tf). Copy and paste line 19. Replace both `cosmosdb_database_name` with your new name for your database from step 3 (e.g. `cosmosdb_inventory_database_name`).
  5. Go to the [cosmosdb.tf file](/src/infra/workload/globalresources/cosmosdb.tf). Copy and paste lines 30-34. Replace `main` with `inventory`. Replace the value for name with `var.cosmosdb_inventory_database_name`. 
  6. Go to the [global resources output file](/src/infra/workload/globalresources/outputs.tf). Copy and paste lines 23-25. Replace  `cosmosdb_database_name` with your new name for your database from step 1 (e.g. `cosmosdb_inventory_database_name`). Replace line 24 with `value = azurerm_cosmosdb_sql_database.inventory.name`
  7. Go to the [key vault secrets file](/src/infra/workload/releaseunit/modules/stamp/keyvault-secrets.tf). Copy and paste line 23, `CosmosDb-DatabaseName`. Replace the secret name with `CosmosDb-Inventory-DatabaseName` and the value with `var.cosmosdb_inventory_database_name`.
  8. Go to the [ADO full release pipeline YAML file](/.ado/pipelines/templates/stages-full-release.yaml). Duplicate line 177 and add replace the cosmosdb references with the names for your new database. 

## Modifying Application Code

For information on the sample application included in the Azure Mission-Critical reference implementation, check out the documentation [here](/docs/reference-implementation/AppDesign-Application-Design.md).

The sample application can be swapped out for your own application. Since the deployment pipeline handles the infrastructure and the application, once you make a change in your application code, you can run the pipeline again to deploy the application without much overhead from the infrastructure stages.  

### Application Structure
The AlwaysOn Sample Application is split into three domains: [BackgroundProcessor](/src/app/AlwaysOn.BackgroundProcessor/), [CatalogService](/src/app/AlwaysOn.CatalogService/), and [HealthService](/src/app/AlwaysOn.HealthService/). The Background Processor handles connecting to the Cosmos DB. The Catalog Service [does something]. The Health Service [does something]. 

Let's say we want to add another service to our application. 

We need the following items to create and integrate our new service:
1. A [.NET project](/src/app/AlwaysOn.CatalogService/) that contains API definitions
2. If you need to update any connections your API needs such as an additional database, you will also need to update the [configuration file for the app](/src/app/AlwaysOn.Shared/SysConfiguration.cs). See line 53 for example of how to include a database.
3. A [Dockerfile](/src/app/AlwaysOn.CatalogService/Dockerfile) to build .NET project (service) and deploy the workload to a Kubernetes cluster
4. A [Helm Chart](/src/app/charts/catalogservice/Chart.yaml) to define our service for Kubernetes 
5. A [set of values for the Helm Chart](/src/app/charts/catalogservice/values.yaml) that defines parameters for the service such as the ports for the workload, scaling, and connection information to Front Door, Ingress, etc.
6. KeyVault Integration is setup in the [Program.cs file](/src/app/AlwaysOn.CatalogService/Program.cs) of each service. 
7. Any configurations such as connection to Cosmos DB, region name, etc. are set in the [SysConfiguration file](/src/app/AlwaysOn.Shared/SysConfiguration.cs) of the [Shared project](/src/app/AlwaysOn.Shared/). 
8. To access data from Cosmos DB, there is a [service](/src/app/AlwaysOn.Shared/Services/CosmosDbService.cs) created in the [Shared project](/src/app/AlwaysOn.Shared/) that is injected into the services. It contains calls to CRUD on the database. 
9. If you have integrated APIM, you will also need to update the [APIM Terraform Template](/docs/example-code/apim.tf) to include a definition for the new API. See below for further instructions.

Adding a new API with APIM
1. Go to the [APIM Terraform template](/docs/example-code/apim.tf) and copy lines 39-63. Replace the resource name of `azurerm_api_management_api` as well as the name and display_name within the definition to the name of your api (e.g. inventoryservice-api and AlwaysOn InventoryService API).
2. Under `azurerm_api_management_api` content_value, you need to include a reference to your [API swagger file](/docs/example-code/catalogservice-api-swagger.json) similar to the example linked here. Change the existing file reference to your new json file.
3. Under `azurerm_api_management_api_diagnostic` or line 57 in the original code, change the `api_name` to reference your new api (e.g. azurerm_api_management_api.inventoryservice.name).


## Deployment

Follow the [Getting Started Guide](./Getting-Started.md)

## Development Process

Developers should use the following naming conventions for creating branches: "feature/[name]", "docs/[name]", or "bug/[name]". Use the appropriate name for what your work entails. 

The main branch will be protected and can only be merged into by initiating a pull request. Each pull request will have several designated approvers. 

Each time you submit a PR, it will be subject to the following rules:
  1. You must deploy your code into the e2e environment successfully before the PR can be approved. 
  2. Once it is successful and you have resolved all comments in your PR, you need to run your deployment pipeline again on your branch and destroy the infrastructure.
  3. Once the infrastructure has been successfully destroyed and your PR has been approved, the PR can be completed and your branch should be deleted.


# Developer Guide

## Tools Required

The following tools and applications should be installed on the client machine used to effectively develop or deploy the Azure Mission-Critical reference implementation:

- Install [Azure CLI](https://docs.microsoft.com/cli/azure/service-page/azure%20cli?view=azure-cli-latest)

- Install [Azure DevOps CLI](https://docs.microsoft.com/azure/devops/cli/?view=azure-devops)

- Install [PowerShell](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1). (Works on Windows, MaxOS and Linux)

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

  1. Go to the [global variables file](/src/infra/workload/globalresources/variables.tf). Copy the variable implementation for the Cosmos DB database name. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  2. Go to the [stamp variables file](/src/infra/workload/releaseunit/modules/stamp/variables.tf). Copy the variable implementation for the Cosmos DB database name. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  3. Go to the [release unit variables file](/src/infra/workload/releaseunit/variables.tf). Copy the variable implementation for the Cosmos DB database name. Replace `cosmosdb_database_name` with a new name for your database (e.g. `cosmosdb_inventory_database_name`).
  4. Go to the [stamp definition file](/src/infra/workload/releaseunit/stamp.tf). Copy the variable implementation for the Cosmos DB database name. Replace both `cosmosdb_database_name` with your new name for your database from step 3 (e.g. `cosmosdb_inventory_database_name`).
  5. Go to the [cosmosdb.tf file](/src/infra/workload/globalresources/cosmosdb.tf). Copy the Cosmos DB database definition. Replace `main` with `inventory`. Replace the value for name with `var.cosmosdb_inventory_database_name`. 
  6. Go to the [global resources output file](/src/infra/workload/globalresources/outputs.tf). Copy the output definition for the Cosmos DB databse name. Replace  `cosmosdb_database_name` with your new name for your database from step 1 (e.g. `cosmosdb_inventory_database_name`). Replace line 24 with `value = azurerm_cosmosdb_sql_database.inventory.name`
  7. Go to the [key vault secrets file](/src/infra/workload/releaseunit/modules/stamp/keyvault-secrets.tf). Copy the secret definition for `CosmosDb-DatabaseName`. Replace the secret name with `CosmosDb-Inventory-DatabaseName` and the value with `var.cosmosdb_inventory_database_name`.
  8. Go to the [ADO full release pipeline YAML file](/.ado/pipelines/templates/stages-full-release.yaml). Duplicate the var definition for the database name and add replace the cosmosdb references with the names for your new database. 

## Modifying Application Code

For information on the sample application included in the Azure Mission-Critical reference implementation, check out the documentation [here](/docs/reference-implementation/AppDesign-Application-Design.md).

The sample application can be swapped out for your own application. Since the deployment pipeline handles the infrastructure and the application, once you make a change in your application code, you can run the pipeline again to deploy the application without much overhead from the infrastructure stages.  

### Application Structure
The AlwaysOn Sample Application is split into three domains: [BackgroundProcessor](/src/app/AlwaysOn.BackgroundProcessor/), [CatalogService](/src/app/AlwaysOn.CatalogService/), and [HealthService](/src/app/AlwaysOn.HealthService/). The Background Processor handles connecting to the Cosmos DB. The Catalog Service gets and inserts catalog items into the Cosmos DB database. The Health Service monitors the health of the underlying services (Catalog Service and Background Processor). 

Let's say we want to add another service to our application. 

We need the following items to create and integrate our new service:
1. A [.NET project](/src/app/AlwaysOn.CatalogService/) that contains API definitions
2. If you need to update any connections your API needs such as an additional database, you will also need to update the [configuration file for the app](/src/app/AlwaysOn.Shared/SysConfiguration.cs). Look for the line that defines a variable called "CosmosDBDatabaseName" for an example of how to connect to the database. 
3. A [Dockerfile](/src/app/AlwaysOn.CatalogService/Dockerfile) to build .NET project (service) and deploy the workload to a Kubernetes cluster
4. A [Helm Chart](/src/app/charts/catalogservice/Chart.yaml) to define our service for Kubernetes 
5. A [set of values for the Helm Chart](/src/app/charts/catalogservice/values.yaml) that defines parameters for the service such as the ports for the workload, scaling, and connection information to Front Door, Ingress, etc.
6. KeyVault Integration is setup in the [Program.cs file](/src/app/AlwaysOn.CatalogService/Program.cs) of each service. 
7. Update the [configuration.yaml](/.ado/pipelines/config/configuration.yaml) to include the new Docker image and Dockerfile. Find the lines that define a Docker file name and Image name (e.g. catalogServiceDockerfile, catalogServiceImageName)
8. Update the [pipeline deployment stages](/.ado/pipelines/templates/stages-full-release.yaml) to include a build job for our new service. Go to the 'buildapplication' stage and add a new job for your new service. Each job uses the [jobs-container-build.yaml](/.ado/pipelines/templates/jobs-container-build.yaml) as the template and uses the image name and Dockerfile name you defined in the previous step.
9. Any configurations such as connection to Cosmos DB, region name, etc. are set in the [SysConfiguration file](/src/app/AlwaysOn.Shared/SysConfiguration.cs) of the [Shared project](/src/app/AlwaysOn.Shared/). 
10. If your new service requires a new database, see above [instructions](#example-1) for creating a new database in Cosmos DB. If you would want to add a new container to the existing main database, look at the existing [container definitions for the CatalogService](/src/infra/workload/globalresources/cosmosdb.tf) and copy a definition.
11. To access data from Cosmos DB, there is a [service](/src/app/AlwaysOn.Shared/Services/CosmosDbService.cs) created in the [Shared project](/src/app/AlwaysOn.Shared/) that is injected into the services. It contains calls to CRUD on the database. If you add a new container or database, you will need to update the [Shared project](/src/app/AlwaysOn.Shared/) with any [models](/src/app/AlwaysOn.Shared/Models/) for your new container and support for accessing your new container in the [database service](/src/app/AlwaysOn.Shared/Services/CosmosDbService.cs) itself. 
12. If you have integrated Azure API Management, you will also need to update the [Azure API Management Terraform Template](/docs/example-code/apim.tf) to include a definition for the new API. See below for further instructions.

Adding a new API with Azure API Management
1. Go to the [Azure API Management Terraform template](/docs/example-code/apim.tf) and copy the api definition. Replace the resource name of `azurerm_api_management_api` as well as the name and display_name within the definition to the name of your api (e.g. inventoryservice-api and AlwaysOn InventoryService API). If you are replacing the Catalog Service API, you do not need to change the path for the API. If you are adding your API in addition to the Catalog Service, you will need to update the path in the API definition in the Terraform template, the swagger file, [the ingress controller](/src/app/charts/catalogservice/templates/ingress.yaml), and the .NET project containing your API definition. 
2. Under `azurerm_api_management_api` content_value, you need to include a reference to your [API swagger file](/docs/example-code/catalogservice-api-swagger.json) similar to the example linked here. Change the existing file reference to your new json file.
3. Copy the definition for `azurerm_api_management_api_diagnostic` for the CatalogService and change the name and`api_name` to reference your new api (e.g. azurerm_api_management_api.inventoryservice.name).

### Smoke Testing
If you have integrated Mission-Critical-Connected with Azure API Management, you will need to add additional Smoke Tests for your new APIs. You will add your tests to the [Smoke Test PowerShell script](/.ado/scripts/SmokeTest.ps1).

## Deployment

Follow the [Getting Started Guide](./Getting-Started.md)

In the e2e environment, each feature branch creates a separate instance of the Mission-Critical-Connected infrastructure. 

In the int environment, the deployment is executed from the main branch on a regular deployment schedule. The deployment schedule set in the reference implementation is every day at 3AM local time. 

## Development Process

Developers should use the following naming conventions for creating branches: "feature/[name]", "docs/[name]", or "bug/[name]". Use the appropriate name for what your work entails. 

The main branch will be protected and can only be merged into by initiating a pull request. Each pull request will have several designated approvers. 

Each time you submit a PR, it will be subject to the following rules:
  1. You must deploy your code into the e2e environment successfully before the PR can be approved. 
  2. Once it is successful and you have resolved all comments in your PR, you need to run your deployment pipeline again on your branch and destroy the infrastructure.
  3. Once the infrastructure has been successfully destroyed and your PR has been approved, the PR can be completed and your branch should be deleted.


# Testing Implementation

The Azure Mission-Critical reference implementation contains various kinds of tests used at different stages. These include:

- **Unit tests**. These validate that the business logic of the application works as expected. Azure Mission-Critical contains a [sample suite of C# unit tests](/src/app/AlwaysOn.Tests/README.md) that are automatically executed before every container build.
- **Load tests**. These can help to evaluate the capacity, scalability and potential bottlenecks of a given workload and stack.
- **Smoke tests**. These identify if the infrastructure and workload are available and act as expected. Smoke tests are executed as part of every deployment.
- **UI tests**. These validate that the user interface was deployed and works as expected. Currently Azure Mission-Critical only [captures screenshots](/src/testing/ui-test-playwright/README.md) of several pages after deployment without any actual testing.
- **Failure Injection tests**. These are done in two ways: First, the Azure Mission-Critical reference implementation integrates Azure Chaos Studio for automated testing as part of the deployment pipelines. Secondly, manual failure injection test can be conducted. See below for details.

Additionally, the Azure Mission-Critical Online repository contains a [user load generator](https://github.com/Azure/Mission-Critical-Online/tree/main/src/testing/userload-generator/README.md) to create synthetic load patterns which can be used to simulate real life traffic. This can also be used completely independently of the reference implementation.

## Failure Injection testing and Chaos Engineering

Distributed applications need to be resilient to service and component outages. Failure Injection testing (also known as Fault Injection or Chaos Engineering) is the practice of subjecting applications and services to real-world stresses and failures.

Resilience is a property of an entire system and injecting faults helps to find issues in the application. Addressing these issues helps to validate application resiliency to unreliable conditions, missing dependencies and other errors.

Manual failure injection testing was initially performed across both global and deployment stamp resources. Please consult the [Failure Injection article](/docs/reference-implementation/DeployAndTest-Testing-FailureInjection.md) for details.

Azure Mission-Critical integrates [Azure Chaos Studio](https://aka.ms/chaosstudio) to deploy and run a set of Azure Chaos Studio Experiments to inject various faults at the global and stamp levels.

## Frameworks

The Azure Mission-Critical reference implementation uses existing testing capabilities and frameworks whenever possible. The subsequent sections contain an overview of the used tools and frameworks.

- [Locust](#locust) for load testing
- [Playwright](#playwright) for UI testing

### Locust

Locust is an open source Load Testing framework. See [locust](https://github.com/Azure/Mission-Critical-Online/tree/main/src/testing/loadtest-locust/README.md) on the [Azure Mission-Critical-Online repository](https://github.com/Azure/Mission-Critical-Online) for more details about the implementation and configuration.

### Playwright

Playwright is an open source Node.js library to automate Chromium, Firefox and WebKit with a single API. See [ui-test-playwright](./ui-test-playwright/README.md) for more details about how UI testing works.

---

[Back to documentation root](/docs/README.md)

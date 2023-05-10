# Networking design decisions

## Virtual network layout

- Each stamp uses its own Virtual Network (VNet). Optionally, through peering in a hub-and-spoke model, it can access other company resources in other spokes or also on-prem via ExpressRoute etc.
- The VNets are expected to pre-provisioned. However, for example for dev environments, the reference implementation is also capable of creating VNets on-demand. In this case, they won't be able to access other company resources due to the missing peering.
- The per-stamp VNet is split into two subnets for Kubernetes (containing all nodes and pods) and private endpoints.
- Private endpoints (Private Link) are used for any of the platform services such as Cosmos DB, Event Hub or Key Vault.

## Global load balancer

**Azure Front Door** (AFD) is used as the global entry point for all incoming client traffic. As the Azure Mission-Critical reference implementation only uses HTTP(S) traffic and uses Web Application Firewall (WAF) capabilities, AFD is the best choice to act as global load balancer. Azure Traffic Manager could be a cost-effective alternative, but it does not have features such as WAF and because it is DNS-based, Azure Traffic Manager usually has longer failover times compared to the TCP Anycast-based Azure Front Door.

See [Custom Domain Support](./Networking-Custom-Domains.md) for more details about the implementation and usage of custom domain names in Azure Mission-Critical.

## Stamp ingress point

- Azure Front Door (AFD) Premium SKU is the only publicly exposed ingress point of the solution.
- The entry point to each stamp is a private **Azure Standard Load Balancer** which is controlled by **Azure Kubernetes Service** (AKS) and the Kubernetes Ingress Controller (Nginx). On top of that Load Balancer AKS creates and manages an **Azure Private Link Service**.
- AFD is using Private Endpoint connectivity to those Private Link Services.
- **Azure Application Gateway** is not used because it does not provide sufficient added benefits (compared to AFD):
  - Web Application Firewall (WAF) is provided as part of Azure Front Door.
  - TLS termination happens on the ingress controller and thus inside the cluster.
  - Using cert-manager, the procurement and renewal of SSL certificates is free of charge (with Let's Encrypt) and does not require additional processes or components.
  - (Auto-)Scaling of the ingress controller pods inside AKS is usually faster than scaling out Application Gateway to more instances.
  - Configuration settings including path-based routing and HTTP header checks could potentially be easier to set up using Application Gateway. However, Nginx provides all the required features and is configured through Helm charts.

## Network security

- Traffic to the cluster can only flow through Private Endpoints, the clusters do not have any public endpoints.
- There is no additional firewall in place (such as Azure Firewall) as it provides no added benefits for reliability but instead would introduce another component adding further management overhead and failure risk.
- All used Azure services are locked down using Private Endpoints.
- In accordance with [Azure Networking Best Practices](https://learn.microsoft.com/azure/security/fundamentals/network-best-practices), all subnets have Network Security Groups (NSGs) assigned.
- TLS termination happens at the ingress controllers. To issue and renew SSL certificates for the cluster ingress controller, the free Let's Encrypt Certificate Authority is used in conjunction with [cert-manager](https://cert-manager.io/docs/) Kubernetes certificate manager.
- As there is no direct traffic between pods, there is no requirement for mutual TLS to be configured.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)

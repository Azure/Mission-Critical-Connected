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

- As Azure Front Door does not (currently) support private origins (backends), the stamp ingress point must be public (private origins are currently in Public Preview with Front Door Premium SKU).
- The entry point to each stamp is a public **Azure Standard Load Balancer** (with one zone-redundant public IP) which is controlled by **Azure Kubernetes Service** (AKS) and the Kubernetes Ingress Controller (Nginx).
- **Azure Application Gateway** is not used because it does not provide sufficient added benefits (compared to AFD):
  - Web Application Firewall (WAF) is provided as part of Azure Front Door.
  - TLS termination happens on the ingress controller and thus inside the cluster.
  - Using cert-manager, the procurement and renewal of SSL certificates is free of charge (with Let's Encrypt) and does not require additional processes or components.
  - Azure Mission-Critical does not have a requirement for the AKS cluster to only run on a private VNet and therefore, having a public Load Balancer in front is acceptable.
  - (Auto-)Scaling of the ingress controller pods inside AKS is usually faster than scaling out Application Gateway to more instances.
  - Configuration settings including path-based routing and HTTP header checks could potentially be easier to set up using Application Gateway. However, Nginx provides all the required features and is configured through Helm charts.

## Network security

- Traffic to the cluster entry points must only come through the global load balancer (Azure Front Door). To ensure this, HTTP header inspection [based on the `X-Azure-FDID` header](https://docs.microsoft.com/azure/frontdoor/front-door-faq#how-do-i-lock-down-the-access-to-my-backend-to-only-azure-front-door-) is implemented on the Nginx ingress controller.
- There is no additional firewall in place (such as Azure Firewall) as it provides no added benefits for reliability but instead would introduce another component adding further management overhead and failure risk.
- Network Service Endpoints are used to lock down traffic to all services which support them.
- In accordance with [Azure Networking Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices), all subnets have Network Security Groups (NSGs) assigned.
- TLS termination happens at the ingress controllers. To issue and renew SSL certificates for the cluster ingress controller, the free Let's Encrypt Certificate Authority is used in conjunction with [cert-manager](https://cert-manager.io/docs/) Kubernetes certificate manager.
- As there is no direct traffic between pods, there is no requirement for mutual TLS to be configured.

### Public compute cluster endpoint

> The first version of the reference implementation exposes the AKS cluster with a public load balancer that is directly accessible over the internet.

- The current version of Azure Front Door only supports backends (origins) with public endpoints; the same would have been true with Traffic Manager if used as an alternative global load balancer. In order to not have a public endpoint on the compute cluster some additional service would have been required in the middle, such as Azure Application Gateway or Azure API Management. However, these would not add functionality, only complexity - and more potential points of failure.
- A risk of publicly accessible cluster ingress points is that attackers could attempt [DDoS](https://en.wikipedia.org/wiki/Denial-of-service_attack) attacks against the endpoints. However, [Azure DDoS protection Basic](https://docs.microsoft.com/azure/ddos-protection/ddos-protection-overview) is in place to lower this risk. If required, DDoS Protection Standard could optionally be enabled to get even more tailored protection.
- If attackers successfully acquire the Front Door ID which is used as the filter on the ingress level, they could directly reach the workload's APIs. However, the attacker would only succeed in circumventing the Web Application Firewall of Front Door. This was judged a small enough risk that the benefit of higher reliability through reduced complexity outweighed the minimal added protection of additional components.

### Requirements to utilize a fully private cluster

As described above, to remove the public endpoint on the compute clusters, another component such as Application Gateway would be required. In the future, the new [Azure Front Door Standard/Premium](https://docs.microsoft.com/azure/frontdoor/standard-premium/overview) offering will eliminate the need for this, as it will support private origins as well (in Public Preview as of February 2022).

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)

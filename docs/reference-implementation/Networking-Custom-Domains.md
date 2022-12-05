# Custom Domain support

The use of a custom domain name is mandatory for the Azure Mission-Critical Connected reference implementation in order to connect Azure Front Door via Private Link to the backends on AKS, as this requires officially validated SSL certificates. The pipeline will take care of the certificate creation and validation using Let's Encrypt, but you need to provision the DNS Zone beforehand. Depending on your scenario, [Azure App Service Domains](https://learn.microsoft.com/azure/app-service/manage-custom-dns-buy-domain) might be an option to easily procure a domain name.

To enable full automation of the deployment, the custom domain is expected to be managed through an Azure DNS Zone. The infrastructure deployment pipeline dynamically creates CNAME records in the Azure DNS zone and maps these automatically to the Azure Front Door instance. Azure DNS zone also enables the Front Door-managed SSL certificates so that there is no need for manual certificate renewals on Front Door.

For `prod` the default domain will be `www.contoso.com`. For `int` and other pre-prod environments, it is suggested that sub-domains such as `int.contoso.com` are used. To keep the access separation these sub-domains should reside in their own Azure DNS zones within the respective subscriptions. For consistency the entry points are formatted similar to `www.int.contoso.com`. For E2E environments which use a custom domain name, it is suggested to use the `sbx` ("sandbox") sub-domain so that the resulting entry point will be similar to `env123.sbx.contoso.com`.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)

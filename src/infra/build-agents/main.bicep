param prefix string
param suffix string = ''
param location string
param environment string

param vmssAdminUsername string = 'alwayson'
@secure()
param vmssAdminPassword string

var prefixsuffix = '${prefix}${suffix}'

var buildAgentSubnetName = 'buildagents-snet'
var jumpserversSubnetName = 'jumpservers-snet'
var privateEndpointsSubnetName = 'private-endpoints-snet'

var default_tags = {
  Owner: 'AlwaysOn V-Team'
  Project: 'AlwaysOn Solution Engineering'
  Toolkit: 'Bicep'
  Environment: environment
  Prefix: prefixsuffix
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${prefixsuffix}-default-nsg'
  location: location
  tags: default_tags
  properties: {}
}

resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${prefixsuffix}-bastion-nsg'
  location: location
  tags: default_tags
  properties: {
    securityRules: [
      {
        name: 'GatewayManager'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          priority: 100
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          protocol: 'Tcp'
          direction: 'Inbound'
        }
      }
      {
        name: 'Internet-Bastion-PublicIP'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          priority: 101
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          protocol: 'Tcp'
          direction: 'Inbound'
        }
      }
      {
        name: 'OutboundVirtualNetwork'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          priority: 103
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          protocol: 'Tcp'
          direction: 'Outbound'
        }
      }
      {
        name: 'OutboundToAzureCloud'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          priority: 104
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          protocol: 'Tcp'
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${prefixsuffix}-vnet'
  location: location
  tags: default_tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/20'
      ]
    }
    subnets: [
      {
        name: buildAgentSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: jumpserversSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
          networkSecurityGroup: {
            id: bastionNsg.id
          }
        }
      }
      {
        name: privateEndpointsSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource keyvaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource keyvaultPeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${keyvaultPrivateDnsZone.name}-link'
  parent: keyvaultPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

resource acrPeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${acrPrivateDnsZone.name}-link'
  parent: acrPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource aksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'azmk8s.io'
  location: 'global'
}

resource aksPeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${aksPrivateDnsZone.name}-link'
  parent: aksPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource blobPeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateDnsZone.name}-link'
  parent: blobPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource tablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
}

resource tablePeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${tablePrivateDnsZone.name}-link'
  parent: tablePrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource buildagentsVmss 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  name: '${prefixsuffix}-buildagents-vmss'
  location: location
  sku: {
    name: 'Standard_F8s_v2'
    capacity: 1
  }

  properties: {
    overprovision: false
    singlePlacementGroup: false
    upgradePolicy: {
      mode:'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          diffDiskSettings: {
            option: 'Local'
          }
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: '${prefixsuffix}buildagent'
        customData: loadFileAsBase64('cloudinit_buildagents.conf')
        adminUsername: vmssAdminUsername
        adminPassword: vmssAdminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${prefixsuffix}-buildagents-vmss-ipconfig'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${buildAgentSubnetName}'
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
}

resource jumpboxesVmss 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  name: '${prefixsuffix}-jumpboxes-vmss'
  location: location
  tags: default_tags
  sku: {
    name: 'Standard_B2s'
    capacity: 1
  }

  properties: {
    overprovision: false
    singlePlacementGroup: false
    upgradePolicy: {
      mode:'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: '${prefixsuffix}jumpbox'
        customData: loadFileAsBase64('cloudinit_jumpservers.conf')
        adminUsername: vmssAdminUsername
        adminPassword: vmssAdminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${prefixsuffix}-jumpboxes-vmss-ipconfig'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${jumpserversSubnetName}'
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${prefixsuffix}-bastion-pip'
  location: location
  tags: default_tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: '${prefixsuffix}-bastionhost'
  location: location
  tags: default_tags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionpublicip'
        properties: {
          publicIPAddress: {
            id: bastionPip.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

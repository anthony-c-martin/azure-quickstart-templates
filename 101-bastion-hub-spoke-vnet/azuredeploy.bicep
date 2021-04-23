@description('The location of all resources')
param location string = resourceGroup().location

@description('The name of the Hub vNet')
param vNetHubName string = 'vnet-hub'

@description('The name of the Spoke vNet')
param vNetSpokeName string = 'vnet-spoke'

@description('The name of the Virtual Machine')
param vmName string = 'vm1'

@description('The size of the Virtual Machine')
param vmSize string = 'Standard_A2_v2'

@description('The administrator username')
param adminUsername string

@description('The administrator password')
@secure()
param adminPassword string

@description('The name of the storage account that will be used for boot diagnostics')
param storageAccountName string

@description('The name of the Azure Bastion host')
param bastionHostName string = 'bastion1'

var vNetHubPrefix = '10.0.0.0/16'
var subnetBastionName = 'AzureBastionSubnet'
var subnetBastionPrefix = '10.0.0.0/27'
var vNetSpokePrefix = '10.1.0.0/16'
var subnetSpokeName = 'Subnet-1'
var subnetSpokePrefix = '10.1.0.0/24'
var bastionPublicIPName_var = 'pip-bastion-01'
var vmPublicIPName_var = 'pip-${vmName}-01'
var nsgName_var = 'nsg-subnet-1'

resource vNetHubName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNetHubName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetHubPrefix
      ]
    }
    subnets: [
      {
        name: subnetBastionName
        properties: {
          addressPrefix: subnetBastionPrefix
        }
      }
    ]
  }
}

resource vNetSpokeName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNetSpokeName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetSpokePrefix
      ]
    }
    subnets: [
      {
        name: subnetSpokeName
        properties: {
          addressPrefix: subnetSpokePrefix
        }
      }
    ]
  }
}

resource vNetHubName_peering_to_vNetSpokeName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vNetHubName_resource
  name: 'peering-to-${vNetSpokeName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNetSpokeName_resource.id
    }
  }
}

resource vNetSpokeName_peering_to_vNetHubName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vNetSpokeName_resource
  name: 'peering-to-${vNetHubName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNetHubName_resource.id
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Inbound-HTTPS'
        properties: {
          description: 'Allows inbound traffic for HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource bastionPublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: bastionPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource vmPublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: vmPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastionHostName_resource 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetHubName, subnetBastionName)
          }
          publicIPAddress: {
            id: bastionPublicIPName.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'ipconfig1'
      }
    ]
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: toLower(storageAccountName)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource vmName_nic_01 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${vmName}-nic-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetSpokeName, subnetSpokeName)
          }
          publicIPAddress: {
            id: vmPublicIPName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    vNetSpokeName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-os-01'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmName_nic_01.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName_resource.properties.primaryEndpoints.blob
      }
    }
  }
}
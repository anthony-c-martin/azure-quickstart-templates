param newStorageAccount string {
  metadata: {
    description: 'The name of the new storage account created to store the VMs disks'
  }
}
param storageType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'The storage type created to store the VMs disks'
  }
  default: 'Standard_LRS'
}
param adminUsername string {
  metadata: {
    description: 'The admin user name for the VM created.'
  }
}
param adminPassword string {
  metadata: {
    description: 'The admin password for the VM created.'
  }
  secure: true
}
param vmSize string {
  allowed: [
    'Standard_A0'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
  ]
  metadata: {
    description: 'The machine type for the server vm.'
  }
  default: 'Standard_D2'
}
param dscPullSrvName string {
  metadata: {
    description: 'The name of the Windows vm.'
  }
}
param dscPullIPDnsName string {
  metadata: {
    description: 'The name of the public ip address'
  }
}
param assetLocation string {
  metadata: {
    description: 'The location of resources such as templates and DSC modules that the script is dependent'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/dsc-pullserver-to-win-server/'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var VirtualNetworkPrefix = '10.0.0.0/16'
var VirtualNetworkSubnet1Name = 'Subnet-1'
var VirtualNetworkSubnet1Prefix = '10.0.0.0/24'
var VirtualNetworkSubnet2Name = 'Subnet-2'
var VirtualNetworkSubnet2Prefix = '10.0.1.0/24'
var dscPullSrvOSDiskName = 'osdisk'
var dscPullSrvSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'dscVirtualNetwork', VirtualNetworkSubnet1Name)
var dscPullSrvStorageAccountContainerName = 'vhds'
var dscPullSrvNicName = 'dscNetworkInterface'
var dscPullIPName = 'dscPublicIPAddress'
var deployDSCPullServerConfigurationFile = '${assetLocation}ConfigurePullServer.ps1.zip'
var deployDSCPullServerConfigurationFunction = 'ConfigurePullServer.ps1\\ConfigurePullServer'
var windowsOSVersion = '2012-R2-Datacenter'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var networkSecurityGroupName = 'default-NSG'

resource newStorageAccount_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccount
  location: location
  tags: {
    displayName: 'Storage'
  }
  properties: {
    accountType: storageType
  }
  dependsOn: []
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-80'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource dscVirtualNetwork 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: 'dscVirtualNetwork'
  location: location
  tags: {
    displayName: 'VirtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        VirtualNetworkPrefix
      ]
    }
    subnets: [
      {
        name: VirtualNetworkSubnet1Name
        properties: {
          addressPrefix: VirtualNetworkSubnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: VirtualNetworkSubnet2Name
        properties: {
          addressPrefix: VirtualNetworkSubnet2Prefix
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource dscPullSrvNicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: dscPullSrvNicName
  location: location
  tags: {
    displayName: 'dscPullSrvNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.0.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: dscPullSrvSubnetRef
          }
          publicIPAddress: {
            id: dscPullIPName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    dscVirtualNetwork
  ]
}

resource dscPullSrvName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: dscPullSrvName
  location: location
  tags: {
    displayName: 'dscPullSrv'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: dscPullSrvName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${dscPullSrvName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: dscPullSrvNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccount_resource
    dscPullSrvNicName_resource
  ]
}

resource dscPullSrvName_deployDSCPullServer 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${dscPullSrvName}/deployDSCPullServer'
  location: location
  tags: {
    displayName: 'deployDSCPullServer'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: deployDSCPullServerConfigurationFile
      configurationFunction: deployDSCPullServerConfigurationFunction
      properties: {}
    }
    protectedSettings: {}
  }
  dependsOn: [
    dscPullSrvName_resource
  ]
}

resource dscPullIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: dscPullIPName
  location: location
  tags: {
    displayName: 'dscPullIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dscPullIPDnsName
    }
  }
  dependsOn: []
}
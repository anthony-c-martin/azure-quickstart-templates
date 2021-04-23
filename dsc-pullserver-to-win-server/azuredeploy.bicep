@description('The name of the new storage account created to store the VMs disks')
param newStorageAccount string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('The storage type created to store the VMs disks')
param storageType string = 'Standard_LRS'

@description('The admin user name for the VM created.')
param adminUsername string

@description('The admin password for the VM created.')
@secure()
param adminPassword string

@allowed([
  'Standard_A0'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
])
@description('The machine type for the server vm.')
param vmSize string = 'Standard_D2'

@description('The name of the Windows vm.')
param dscPullSrvName string

@description('The name of the public ip address')
param dscPullIPDnsName string

@description('The location of resources such as templates and DSC modules that the script is dependent')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/dsc-pullserver-to-win-server/'

@description('Location for all resources.')
param location string = resourceGroup().location

var VirtualNetworkPrefix = '10.0.0.0/16'
var VirtualNetworkSubnet1Name = 'Subnet-1'
var VirtualNetworkSubnet1Prefix = '10.0.0.0/24'
var VirtualNetworkSubnet2Name = 'Subnet-2'
var VirtualNetworkSubnet2Prefix = '10.0.1.0/24'
var dscPullSrvOSDiskName = 'osdisk'
var dscPullSrvSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'dscVirtualNetwork', VirtualNetworkSubnet1Name)
var dscPullSrvStorageAccountContainerName = 'vhds'
var dscPullSrvNicName_var = 'dscNetworkInterface'
var dscPullIPName_var = 'dscPublicIPAddress'
var deployDSCPullServerConfigurationFile = '${assetLocation}ConfigurePullServer.ps1.zip'
var deployDSCPullServerConfigurationFunction = 'ConfigurePullServer.ps1\\ConfigurePullServer'
var windowsOSVersion = '2012-R2-Datacenter'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var networkSecurityGroupName_var = 'default-NSG'

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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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
            id: networkSecurityGroupName.id
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
}

resource dscPullSrvNicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: dscPullSrvNicName_var
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
            id: dscPullIPName.id
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
          id: dscPullSrvNicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccount_resource
  ]
}

resource dscPullSrvName_deployDSCPullServer 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: dscPullSrvName_resource
  name: 'deployDSCPullServer'
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
}

resource dscPullIPName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: dscPullIPName_var
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
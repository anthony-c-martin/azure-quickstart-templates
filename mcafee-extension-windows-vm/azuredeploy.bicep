@description('Storage Account Name')
param newStorageAccountName string

@description('Public IP Address Name')
param publicIPAddressName string

@allowed([
  'Dynamic'
])
@description('Public IP Address Type')
param publicIPAddressType string = 'Dynamic'

@description('Name of the VM')
param vmName string

@description('Size of the VM')
param vmSize string = 'Standard_D3'

@description('Image Publisher')
param imagePublisher string = 'MicrosoftWindowsServer'

@description('Image Offer')
param imageOffer string = 'WindowsServer'

@description('Image SKU')
param imageSKU string = '2012-R2-Datacenter'

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('VNET Name')
param virtualNetworkName string

@description('VNET address space')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet 1 name')
param subnet1Name string = 'Subnet-1'

@description('Subnet 1 address space')
param subnet1Prefix string = '10.0.0.0/24'

@description('Name of the NIC')
param nicName string

@description('Extension name')
param vmExtensionName string

@description('Location for all resources.')
param location string = resourceGroup().location

var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var storageAccountType = 'Standard_LRS'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName_resource
  name: '${vmExtensionName}'
  location: location
  properties: {
    publisher: 'McAfee.EndpointSecurity'
    type: 'McAfeeEndpointSecurity'
    typeHandlerVersion: '6.0'
    settings: {
      featureVS: 'true'
      featureBP: 'true'
      featureFW: 'true'
      relayServer: 'false'
    }
    protectedSettings: null
  }
}
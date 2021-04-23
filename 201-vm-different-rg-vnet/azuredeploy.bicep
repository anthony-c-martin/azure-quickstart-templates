@description('Name of new storage account')
param newStorageAccountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
@description('Type of storage account')
param storageAccountType string = 'Standard_LRS'

@description('Name of Public IP')
param publicIPName string

@allowed([
  'Dynamic'
])
@description('Type of Public Address')
param publicIPAddressType string = 'Dynamic'

@description('Name of the VM')
param vmName string

@description('Size of the VM')
param vmSize string = 'Standard_A1_v2'

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@allowed([
  '14.04.5-LTS'
  '16.04-LTS'
  '18.04-LTS'
])
@description('Image SKU')
param imageSKU string = '18.04-LTS'

@description('VM Admin Username')
param adminUsername string

@description('VNET Name')
param virtualNetworkName string

@description('Resource Group VNET is deployed in')
param virtualNetworkResourceGroup string

@description('Name of the subnet inside the VNET')
param subnet1Name string

@description('Network Interface Name')
param nicName string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName_resource.id
          }
          subnet: {
            id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet1Name)
          }
        }
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
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
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId('Microsoft.Storage/storageAccounts', toLower(newStorageAccountName))).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    newStorageAccountName_resource
  ]
}
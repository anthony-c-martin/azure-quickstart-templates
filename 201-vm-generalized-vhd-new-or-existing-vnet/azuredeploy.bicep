@description('Name of the VM')
param vmName string = 'newvm'

@allowed([
  'Windows'
  'Linux'
])
@description('Type of OS on the existing vhd')
param osType string = 'Windows'

@description('Uri of the existing VHD in ARM standard or premium storage')
param osDiskVhdUri string

@description('Size of the VM')
param vmSize string = 'Standard_D2s_v3'

@allowed([
  'new'
  'existing'
])
@description('Specify whether to create a new or existing virtual network for the VM.')
param vNetNewOrExisting string = 'new'

@description('Name of the existing VNET')
param virtualNetworkName string = 'newVnet'

@description('Name of the existing VNET resource group')
param virtualNetworkResourceGroup string = resourceGroup().name

@description('Name of the subnet in the virtual network you want to use')
param subnetName string = 'subnet-1'

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsNameForPublicIP string = 'vm-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('User name for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

var diagStorageAccountName_var = '${uniqueString(resourceGroup().id)}specvm'
var subnetRef = resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var nicName_var = 'nic'
var publicIPAddressName_var = 'publicIp'
var imageName_var = '${vmName}-image'
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = if (vNetNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: diagStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'NetworkInterface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource imageName 'Microsoft.Compute/images@2020-06-01' = {
  name: imageName_var
  location: location
  properties: {
    hyperVGeneration: 'V2'
    storageProfile: {
      osDisk: {
        osType: osType
        osState: 'Generalized'
        blobUri: osDiskVhdUri
        caching: 'ReadWrite'
        storageAccountType: 'Standard_LRS'
      }
    }
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
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
        id: imageName.id
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagStorageAccountName_var).primaryEndpoints.blob
      }
    }
  }
}
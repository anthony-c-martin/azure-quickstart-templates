@description('Username for the Virtual Machine.')
param username string

@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param newStorageAccountName string

@description('Name of the vm, will be used as DNS Name for the Public IP used to access the Virtual Machine.')
param vmName string

@allowed([
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
])
@description('VM size')
param vmSize string

@allowed([
  '14.04.5-LTS'
  '12.04.5-LTS'
])
@description('The Ubuntu version')
param ubuntuOSVersion string = '14.04.5-LTS'

@allowed([
  'Push'
  'Pull'
  'Install'
  'Register'
])
@description('The functional mode, push MOF configuration (Push), distribute MOF configuration (Pull), install custom DSC module (Install)')
param mode string = 'Push'

@description('The name of the storage account that contains the MOF file/meta MOF file/resource ZIP file')
param storageAccountName string = ''

@description('The key of the storage account that contains the MOF file/meta MOF file/resource ZIP file')
param storageAccountKey string = ''

@description('The uri of the MOF file/Meta MOF file/resource ZIP file')
param fileUri string = ''

@description('The URL of the Azure Automation account')
param registrationUrl string = ''

@description('The access key of the Azure Automation account')
param registrationKey string = ''

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

var virtualNetworkName_var = 'vnet-dsc'
var nicName_var = vmName
var publicIPAddressName_var = vmName
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'dsc'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var vmStorageAccountContainerName = 'vhds'
var storageAccountType = 'Standard_LRS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var OSDiskName = 'osdiskfordsc'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${username}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName_var
  location: location
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
  dependsOn: [
    virtualNetworkName
  ]
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
      adminUsername: username
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
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
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
  ]
}

resource vmName_enabledsc 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName_resource
  name: 'enabledsc'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'DSCForLinux'
    typeHandlerVersion: '2.0'
    settings: {
      Mode: mode
      FileUri: fileUri
    }
    protectedSettings: {
      StorageAccountName: storageAccountName
      StorageAccountKey: storageAccountKey
      RegistrationUrl: registrationUrl
      RegistrationKey: registrationKey
    }
  }
}
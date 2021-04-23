@description('Size of vm')
param vmSize string = 'Standard_D1_v2'

@description('Username for the Virtual Machine.')
param username string

@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param newStorageAccountName string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsNameForPublicIP string

@allowed([
  'RebootIfNeed'
  'Required'
  'NotRequired'
  'Auto'
])
@description('The reboot behavior after patching.')
param rebootAfterPatch string = 'Auto'

@allowed([
  'Important'
  'ImportantAndRecommended'
])
@description('Type of patches to install.')
param category string = 'ImportantAndRecommended'

@description('The allowed total time for installation.')
param installDuration string = '01:00'

@allowed([
  true
  false
])
@description('Patch the OS immediately.')
param oneoff bool = false

@description('The patching date (of the week)You can specify multiple days in a week.')
param dayOfWeek string = 'Sunday|Wednesday'

@description('Start time of patching.')
param startTime string = '03:00'

@description('The uri of the idle test script')
param idleTestScript string = ''

@description('The uri of the healthy test script')
param healthyTestScript string = ''

@description('The name of storage account.')
param storageAccountName string = ''

@description('The access key of storage account.')
param storageAccountKey string = ''

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

var scenarioPrefix = 'ospatchingLinux'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '18.04-LTS'
var nicName_var = '${scenarioPrefix}Nic'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = '${scenarioPrefix}Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = '${scenarioPrefix}PublicIp'
var publicIPAddressType = 'Dynamic'
var vmName_var = '${scenarioPrefix}VM'
var virtualNetworkName_var = '${scenarioPrefix}Vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
        name: '${vmName_var}_OSDisk'
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

resource vmName_installospatching 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName
  name: 'installospatching'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'OSPatchingForLinux'
    typeHandlerVersion: '2.0'
    settings: {
      disabled: false
      stop: false
      rebootAfterPatch: rebootAfterPatch
      category: category
      installDuration: installDuration
      oneoff: oneoff
      intervalOfWeeks: '1'
      dayOfWeek: dayOfWeek
      startTime: startTime
      vmStatusTest: {
        local: false
        idleTestScript: idleTestScript
        healthyTestScript: healthyTestScript
      }
    }
    protectedSettings: {
      storageAccountName: storageAccountName
      storageAccountKey: storageAccountKey
    }
  }
}
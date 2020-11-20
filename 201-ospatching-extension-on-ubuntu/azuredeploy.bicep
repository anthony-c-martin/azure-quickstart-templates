param vmSize string {
  metadata: {
    description: 'Size of vm'
  }
  default: 'Standard_D1_v2'
}
param username string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param rebootAfterPatch string {
  allowed: [
    'RebootIfNeed'
    'Required'
    'NotRequired'
    'Auto'
  ]
  metadata: {
    description: 'The reboot behavior after patching.'
  }
  default: 'Auto'
}
param category string {
  allowed: [
    'Important'
    'ImportantAndRecommended'
  ]
  metadata: {
    description: 'Type of patches to install.'
  }
  default: 'ImportantAndRecommended'
}
param installDuration string {
  metadata: {
    description: 'The allowed total time for installation.'
  }
  default: '01:00'
}
param oneoff bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Patch the OS immediately.'
  }
  default: false
}
param dayOfWeek string {
  metadata: {
    description: 'The patching date (of the week)You can specify multiple days in a week.'
  }
  default: 'Sunday|Wednesday'
}
param startTime string {
  metadata: {
    description: 'Start time of patching.'
  }
  default: '03:00'
}
param idleTestScript string {
  metadata: {
    description: 'The uri of the idle test script'
  }
  default: ''
}
param healthyTestScript string {
  metadata: {
    description: 'The uri of the healthy test script'
  }
  default: ''
}
param storageAccountName string {
  metadata: {
    description: 'The name of storage account.'
  }
  default: ''
}
param storageAccountKey string {
  metadata: {
    description: 'The access key of storage account.'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

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

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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
    newStorageAccountName_res
  ]
}

resource vmName_installospatching 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName_var}/installospatching'
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
  dependsOn: [
    vmName
  ]
}
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
param vmName string {
  metadata: {
    description: 'Name of the vm, will be used as DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param vmSize string {
  allowed: [
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
  ]
  metadata: {
    description: 'VM size'
  }
}
param ubuntuOSVersion string {
  allowed: [
    '14.04.5-LTS'
    '12.04.5-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version'
  }
  default: '14.04.5-LTS'
}
param mode string {
  allowed: [
    'Push'
    'Pull'
    'Install'
    'Register'
  ]
  metadata: {
    description: 'The functional mode, push MOF configuration (Push), distribute MOF configuration (Pull), install custom DSC module (Install)'
  }
  default: 'Push'
}
param fileUri string {
  metadata: {
    description: 'The uri of the MOF file/Meta MOF file/resource ZIP file'
  }
  default: ''
}
param registrationUrl string {
  metadata: {
    description: 'The URL of the Azure Automation account'
  }
  default: ''
}
param registrationKey string {
  metadata: {
    description: 'The access key of the Azure Automation account'
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

var virtualNetworkName = 'vnet-dsc'
var nicName = vmName
var publicIPAddressName = vmName
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'dsc'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmName
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
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
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2015-05-01-preview' = {
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
        name: 'osdisk1'
        vhd: {
          uri: 'http://${newStorageAccountName}.blob.core.windows.net/${vmStorageAccountContainerName}/${OSDiskName}.vhd'
        }
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
    nicName_resource
  ]
}

resource vmName_enabledsc 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/enabledsc'
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
      RegistrationUrl: registrationUrl
      RegistrationKey: registrationKey
    }
  }
  dependsOn: [
    vmName_resource
  ]
}
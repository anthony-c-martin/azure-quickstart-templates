param adminUsername string {
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
  default: 'Standard_D1'
}
param ubuntuOSVersion string {
  allowed: [
    '14.04.2-LTS'
    '15.10'
    '14.10'
  ]
  metadata: {
    description: 'The Ubuntu version'
  }
  default: '14.04.2-LTS'
}
param userName string {
  metadata: {
    description: 'The user name whose password you want to change'
  }
}
param password string {
  metadata: {
    description: 'The new password'
  }
  secure: true
  default: ''
}
param sshKey string {
  metadata: {
    description: 'The new public key'
  }
  default: ''
}
param resetSSH bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Whether to reset ssh'
  }
  default: false
}
param userNameToRemove string {
  metadata: {
    description: 'The user name you want to remove'
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

var virtualNetworkName_var = 'vnet-vmaccess'
var nicName_var = vmName
var publicIPAddressName_var = vmName
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'VMAccess'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var storageAccountType = 'Standard_LRS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
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

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
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
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName}.blob.core.windows.net'
      }
    }
  }
}

resource vmName_enablevmaccess 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/enablevmaccess'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: 'true'
    settings: {}
    protectedSettings: {
      username: userName
      password: password
      reset_ssh: resetSSH
      ssh_key: sshKey
      remove_user: userNameToRemove
    }
  }
}
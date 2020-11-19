param newStorageAccountName string {
  metadata: {
    description: 'Name of new storage account'
  }
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
  ]
  metadata: {
    description: 'Type of storage account'
  }
  default: 'Standard_LRS'
}
param publicIPName string {
  metadata: {
    description: 'Name of Public IP'
  }
}
param publicIPAddressType string {
  allowed: [
    'Dynamic'
  ]
  metadata: {
    description: 'Type of Public Address'
  }
  default: 'Dynamic'
}
param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_A1_v2'
}
param imagePublisher string {
  metadata: {
    description: 'Image Publisher'
  }
  default: 'Canonical'
}
param imageOffer string {
  metadata: {
    description: 'Image Offer'
  }
  default: 'UbuntuServer'
}
param imageSKU string {
  allowed: [
    '14.04.5-LTS'
    '16.04-LTS'
    '18.04-LTS'
  ]
  metadata: {
    description: 'Image SKU'
  }
  default: '18.04-LTS'
}
param adminUsername string {
  metadata: {
    description: 'VM Admin Username'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'VNET Name'
  }
}
param virtualNetworkResourceGroup string {
  metadata: {
    description: 'Resource Group VNET is deployed in'
  }
}
param subnet1Name string {
  metadata: {
    description: 'Name of the subnet inside the VNET'
  }
}
param nicName string {
  metadata: {
    description: 'Network Interface Name'
  }
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

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPName_res 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource nicName_res 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName_res.id
          }
          subnet: {
            id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet1Name)
          }
        }
      }
    ]
  }
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
          id: nicName_res.id
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
    newStorageAccountName_res
  ]
}
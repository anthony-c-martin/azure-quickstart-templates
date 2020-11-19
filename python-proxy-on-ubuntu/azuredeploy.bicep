param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique dns name for public ip'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machines'
  }
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
  metadata: {
    description: 'Image SKU'
  }
  default: '14.04.5-LTS'
}
param vmSize string {
  metadata: {
    description: 'Size of the Virtual Machine'
  }
  default: 'Standard_A0'
}
param publicIPAddressName string {
  metadata: {
    description: 'Name of Public IP Address Name'
  }
}
param vmName string {
  metadata: {
    description: 'Name of Virtual Machine'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of Virtual Network'
  }
}
param nicName string {
  metadata: {
    description: 'Name of Network Interface'
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

var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet2Name = 'Subnet-2'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var publicIPAddressType = 'Dynamic'
var storageAccountType = 'Standard_LRS'
var vnetID = virtualNetworkName_res.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
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

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_res 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource nicName_res 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_res.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_res.id
        }
      ]
      inputEndpoints: [
        {
          enableDirectServerReturn: 'False'
          endpointName: 'SSH'
          privatePort: 22
          publicPort: 22
          protocol: 'Tcp'
        }
        {
          enableDirectServerReturn: 'False'
          endpointName: 'Http'
          privatePort: 8888
          publicPort: 8888
          protocol: 'Tcp'
        }
      ]
    }
  }
}

resource vmName_installPythonProxy 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/installPythonProxy'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/python-proxy-on-ubuntu/python-proxy-install-ubuntu.sh'
      ]
      commandToExecute: 'sh python-proxy-install-ubuntu.sh'
    }
  }
}
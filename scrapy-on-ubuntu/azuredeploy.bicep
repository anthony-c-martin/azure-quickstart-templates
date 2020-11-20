param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'This is the dns name of the public IP'
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
param spiderName string {
  metadata: {
    description: 'Name of the spider'
  }
  default: 'myspider.py'
}
param spiderUri string {
  metadata: {
    description: 'Uri of the spider source'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/scrapy-on-ubuntu/myspider.py'
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

var storageAccountType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vmStorageAccountContainerName = 'vhds'
var OSDiskName = 'osdiskforscrapy'
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
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_res 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
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

resource nicName_res 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: resourceGroup().location
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
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_res
  ]
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: resourceGroup().location
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
    }
  }
  dependsOn: [
    newStorageAccountName_res
  ]
}

resource vmName_installscrapy 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/installscrapy'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/scrapy-on-ubuntu/scrapy-install-ubuntu.sh'
        spiderUri
      ]
      commandToExecute: 'sh scrapy-install-ubuntu.sh ${spiderName}'
    }
  }
  dependsOn: [
    vmName_res
  ]
}
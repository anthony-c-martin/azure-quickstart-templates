param location string {
  metadata: {
    description: 'Network Security Group Deployment Location'
  }
  default: 'westus'
}
param computeApiVersion string {
  allowed: [
    '2015-05-01-preview'
    '2015-06-15'
  ]
  metadata: {
    description: 'API Version for the Compute Resources'
  }
  default: '2015-06-15'
}
param tag object {
  metadata: {
    description: 'Tag Values'
  }
  default: {
    key1: 'key'
    value1: 'value'
  }
}
param vmName string {
  metadata: {
    description: 'Virtual Machine Name'
  }
  default: 'vmName'
}
param vmSize string {
  metadata: {
    description: 'Virtual Machine Size'
  }
  default: 'Standard_D2'
}
param adminUsername string {
  metadata: {
    description: 'Admin Username of Virtual Machine to SSH or RDP'
  }
  default: 'sysgain'
}
param adminPassword string {
  metadata: {
    description: 'Admin Password of Virtual Machine to SSH or RDP'
  }
  secure: true
  default: 'Sysga1n4205!'
}
param imagePublisher string {
  metadata: {
    description: 'Virtual Machine Image Publisher'
  }
  default: ' '
}
param imageOffer string {
  metadata: {
    description: 'Virtual Machine Image Offer'
  }
  default: ' '
}
param imageSKU string {
  metadata: {
    description: 'Virtual Machine Image SKU'
  }
  default: ' '
}
param imageVersion string {
  metadata: {
    description: 'Virtual Machine Image Version'
  }
  default: 'latest'
}
param storageAccountName string {
  metadata: {
    description: 'Storage Account Name'
  }
  default: 'storageAccountName'
}
param vmStorageAccountContainerName string {
  metadata: {
    description: 'Caintainer name in the storage account'
  }
  default: 'vhds'
}
param networkInterfaceName string {
  metadata: {
    description: 'Network Security Group Name'
  }
  default: 'networkInterfaceName'
}
param informaticaTags object
param quickstartTags object

resource vmName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  plan: {
    name: imageSKU
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
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
          id: resourceId('Microsoft.Network/networkInterfaces', networkInterfaceName)
        }
      ]
    }
  }
}
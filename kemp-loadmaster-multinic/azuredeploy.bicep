param balPassword string {
  metadata: {
    description: 'Password for bal account'
  }
  secure: true
}
param balUsername string {
  metadata: {
    description: 'Username for bal account'
  }
}
param existingvirtualNetworkResourceGroup string {
  metadata: {
    description: 'Name of the resource group that contains the existing virutal network.'
  }
}
param existingvirtualNetworkName string {
  metadata: {
    description: 'Name of the existing virutal network the KEMP LoadMaster will be deployed to.'
  }
}
param existingsubnetName1 string {
  metadata: {
    description: 'Name of the existing subnet in the virtual network you want to use'
  }
}
param existingsubnetName2 string {
  metadata: {
    description: 'Name of the existing subnet in the virtual network you want to use'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmSize string {
  metadata: {
    description: 'Size of the VM.'
  }
  default: 'Standard_A2_V2'
}

var publicIPAddressType = 'Dynamic'
var vmName_var = 'VLM-MultiNIC'
var subnetRef1 = resourceId(existingvirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingvirtualNetworkName, existingsubnetName1)
var subnetRef2 = resourceId(existingvirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingvirtualNetworkName, existingsubnetName2)
var nicName1_var = 'NIC1'
var nicName2_var = 'NIC2'
var dnsNameForPublicIP = 'vlm${uniqueString(resourceGroup().id)}'
var imageOffer = 'vlm-azure'
var imagePublisher = 'kemptech'
var imageVersion = 'latest'
var imageSKU = 'basic-byol'
var publicIPAddressName_var = vmName_var

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nicName1 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName1_var
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
            id: subnetRef1
          }
        }
      }
    ]
  }
}

resource nicName2 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName2_var
  location: location
  tags: {
    displayName: 'NetworkInterface2'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef2
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  tags: {
    displayName: 'VirtualMachine'
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
      computerName: vmName_var
      adminUsername: balUsername
      adminPassword: balPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
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
          id: nicName1.id
          properties: {
            primary: true
          }
        }
        {
          id: nicName2.id
          properties: {
            primary: false
          }
        }
      ]
    }
  }
}

output FQDN string = reference(publicIPAddressName.id, '2019-11-01').dnsSettings.fqdn
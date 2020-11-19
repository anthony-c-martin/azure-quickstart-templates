param storageAccountType string {
  metadata: {
    description: 'Type of the Storage Account'
  }
  default: 'Standard_LRS'
}
param publicIPAddressName string {
  metadata: {
    description: 'Public IP Address Name'
  }
}
param publicIPAddressType string {
  allowed: [
    'Dynamic'
  ]
  metadata: {
    description: 'Public IP Address Type'
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
  default: 'Standard_A0'
}
param imagePublisher string {
  metadata: {
    description: 'Image Publisher'
  }
  default: 'MicrosoftWindowsServer'
}
param imageOffer string {
  metadata: {
    description: 'Image Offer'
  }
  default: 'WindowsServer'
}
param imageSKU string {
  metadata: {
    description: 'Image SKU'
  }
  default: '2012-R2-Datacenter'
}
param adminUsername string {
  metadata: {
    description: 'Admin username'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password'
  }
  secure: true
}
param virtualNetworkName string {
  metadata: {
    description: 'VNET Name'
  }
}
param addressPrefix string {
  metadata: {
    description: 'VNET address space'
  }
  default: '10.0.0.0/16'
}
param subnet1Name string {
  metadata: {
    description: 'Subnet 1 name'
  }
  default: 'Subnet-1'
}
param subnet1Prefix string {
  metadata: {
    description: 'Subnet 1 address space'
  }
  default: '10.0.0.0/24'
}
param nicName string {
  metadata: {
    description: 'Name of the NIC'
  }
}
param vmExtensionName string {
  metadata: {
    description: 'Extension name'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = '${uniqueString(resourceGroup().id)}storage'
var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: storageAccountName
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
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
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
            id: subnet1Ref
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Symantec'
    type: 'SymantecEndpointProtection'
    typeHandlerVersion: '12.1'
    settings: null
    protectedSettings: null
  }
  dependsOn: [
    vmName_resource
  ]
}
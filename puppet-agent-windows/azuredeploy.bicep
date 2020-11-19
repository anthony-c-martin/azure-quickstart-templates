param storageAccountNamePrefix string {
  maxLength: 11
  metadata: {
    description: 'Name prefix of the storage account to hold your VM disk.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin user name for the Virtual Machines'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password name for the Virtual Machines'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'VM Size for creating the Virtual Machine'
  }
  default: 'Standard_D2'
}
param puppet_master_server_url string {
  metadata: {
    description: 'Puppet Master URL'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var vmExtensionName = 'PuppetEnterpriseAgent'
var vmName = dnsLabelPrefix
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'MyVNET'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var nicName = 'myVMNic'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2012-R2-Datacenter'
var storageAccountName = replace(replace(toLower(concat(storageAccountNamePrefix, uniqueString(resourceGroup().id))), '-', ''), '.', '')
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'PuppetLabs'
    type: 'PuppetEnterpriseAgent'
    typeHandlerVersion: '3.2'
    settings: {
      puppet_master_server: puppet_master_server_url
    }
    protectedSettings: {
      placeHolder: {
        placeHolder: 'placeHolder'
      }
    }
  }
  dependsOn: [
    vmName_resource
  ]
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'Size of VM'
  }
}
param sizeOfEachDataDiskInGB string {
  metadata: {
    description: 'Size of each data disk in GB'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = '${uniqueString(resourceGroup().id)}saddiskvm'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2019-Datacenter'
var imageVersion = 'latest'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var storageAccountType = 'Standard_LRS'
var virtualNetworkName = 'myVNET'
var vmName = 'myVM'
var nicName = 'myNIC'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet1Name)
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
        version: imageVersion
      }
      dataDisks: [
        {
          diskSizeGB: sizeOfEachDataDiskInGB
          lun: 0
          createOption: 'Empty'
        }
        {
          diskSizeGB: sizeOfEachDataDiskInGB
          lun: 1
          createOption: 'Empty'
        }
        {
          diskSizeGB: sizeOfEachDataDiskInGB
          lun: 2
          createOption: 'Empty'
        }
        {
          diskSizeGB: sizeOfEachDataDiskInGB
          lun: 3
          createOption: 'Empty'
        }
      ]
      osDisk: {
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${storageAccountName}', '2019-06-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}
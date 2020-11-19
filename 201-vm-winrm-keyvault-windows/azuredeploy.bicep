param dnsNameForPublicIP string {
  metadata: {
    description: 'DNS Name for the Public IP. Must be lowercase.'
  }
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
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_A2_v2'
}
param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
  default: 'WinRmVm'
}
param vaultResourceId string {
  metadata: {
    description: 'ResourceId of the KeyVault'
  }
}
param certificateUrl string {
  metadata: {
    description: 'Url of the certificate with version in KeyVault e.g. https://testault.vault.azure.net/secrets/testcert/b621es1db241e56a72d037479xab1r7'
  }
}

var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'myVNET'
var nicName = 'myNIC'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet1Name)
var networkSecurityGroupName = '${subnet1Name}-nsg'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-09-01' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: nicName
  location: resourceGroup().location
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      secrets: [
        {
          sourceVault: {
            id: vaultResourceId
          }
          vaultCertificates: [
            {
              certificateUrl: certificateUrl
              certificateStore: 'My'
            }
          ]
        }
      ]
      windowsConfiguration: {
        provisionVMAgent: true
        winRM: {
          listeners: [
            {
              protocol: 'Http'
            }
            {
              protocol: 'Https'
              certificateUrl: certificateUrl
            }
          ]
        }
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
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
    nicName_resource
  ]
}
@description('DNS Name for the Public IP. Must be lowercase.')
param dnsNameForPublicIP string

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Image Publisher')
param imagePublisher string = 'MicrosoftWindowsServer'

@description('Image Offer')
param imageOffer string = 'WindowsServer'

@description('Image SKU')
param imageSKU string = '2012-R2-Datacenter'

@description('Size of the VM')
param vmSize string = 'Standard_A2_v2'

@description('Name of the VM')
param vmName string = 'WinRmVm'

@description('ResourceId of the KeyVault')
param vaultResourceId string

@description('Url of the certificate with version in KeyVault e.g. https://testault.vault.azure.net/secrets/testcert/b621es1db241e56a72d037479xab1r7')
param certificateUrl string

var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = 'myVNET'
var nicName_var = 'myNIC'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
var networkSecurityGroupName_var = '${subnet1Name}-nsg'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName_var
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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: nicName_var
  location: resourceGroup().location
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
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
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
          id: nicName.id
        }
      ]
    }
  }
}
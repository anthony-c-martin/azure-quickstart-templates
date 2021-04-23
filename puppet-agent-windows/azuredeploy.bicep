@description('Unique DNS Name')
param dnsLabelPrefix string = 'puppet-${uniqueString(resourceGroup().id)}'

@description('Admin user name for the Virtual Machines')
param adminUsername string

@description('Admin password name for the Virtual Machines')
@secure()
param adminPassword string

@description('VM Size for creating the Virtual Machine')
param vmSize string = 'Standard_D2_v3'

@description('Puppet Master URL')
param puppet_master_server_url string

@description('Location for all resources.')
param location string = resourceGroup().location

var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
var vmExtensionName = 'PuppetEnterpriseAgent'
var vmName_var = take(dnsLabelPrefix, 15)
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = 'MyVNET'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var nicName_var = 'myVMNic'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2019-Datacenter'
var networkSecurityGroupName_var = 'default-NSG'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: virtualNetworkName_var
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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: nicName_var
  location: location
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

resource vmName 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
        name: '${vmName_var}_OSDisk'
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

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmName
  name: '${vmExtensionName}'
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
}
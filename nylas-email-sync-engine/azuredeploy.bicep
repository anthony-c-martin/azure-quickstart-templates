@description('User name for the Virtual Machine.')
param adminUsername string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string

@allowed([
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
])
@description('Size of the VM')
param vmSize string = 'Standard_D2_v2'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var storageAccountName_var = '${uniqueString(resourceGroup().id)}nylas'
var imagePublisher = 'credativ'
var imageOffer = 'debian'
var imageSKU = '8'
var OSDiskName = 'osdiskNylas'
var nicName_var = 'nylasNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var nsgName_var = 'nylasNSG'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'nylasPublicIP'
var publicIPAddressType = 'Static'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = 'nylasSyncEngineVM'
var virtualNetworkName_var = 'nylasVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: '5000-5009'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5000-5009'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
      {
        name: '8000'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Inbound'
        }
      }
      {
        name: '5555'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5555'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
        }
      }
      {
        name: '9200'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9200'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1004
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${storageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource vmName_nylasScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName
  name: 'nylasScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/nylas-email-sync-engine/install.sh'
      ]
      commandToExecute: 'sh install.sh ${adminUsername}'
    }
  }
}

output hostname string = '${dnsLabelPrefix}.${location}.cloudapp.azure.com'
output sshCommand string = 'ssh ${adminUsername}@${dnsLabelPrefix}.${location}.cloudapp.azure.com'
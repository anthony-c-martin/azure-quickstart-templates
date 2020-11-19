param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param vmSize string {
  allowed: [
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
  ]
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_D2_v2'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
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

var storageAccountName = '${uniqueString(resourceGroup().id)}nylas'
var imagePublisher = 'credativ'
var imageOffer = 'debian'
var imageSKU = '8'
var OSDiskName = 'osdiskNylas'
var nicName = 'nylasNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var nsgName = 'nylasNSG'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'nylasPublicIP'
var publicIPAddressType = 'Static'
var vmStorageAccountContainerName = 'vhds'
var vmName = 'nylasSyncEngineVM'
var virtualNetworkName = 'nylasVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
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
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName_resource.id
    }
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    nsgName_resource
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName
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
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${storageAccountName}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_nylasScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/nylasScript'
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
  dependsOn: [
    vmName_resource
  ]
}

output hostname string = '${dnsLabelPrefix}.${location}.cloudapp.azure.com'
output sshCommand string = 'ssh ${adminUsername}@${dnsLabelPrefix}.${location}.cloudapp.azure.com'
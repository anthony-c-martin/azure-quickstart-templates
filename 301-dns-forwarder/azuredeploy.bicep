param vmName string {
  metadata: {
    description: 'Name of the Virtual Machine.'
  }
  default: 'dnsproxy'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param storageAccountName string {
  metadata: {
    description: 'The name of the storage account for diagnostics.  Storage account names must be globally unique.'
  }
}
param forwardIP string {
  metadata: {
    description: 'This is the IP address to forward DNS queries to. The default value represents Azure\'s internal DNS recursive resolvers.'
  }
  default: '168.63.129.16'
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
param vmSize string {
  metadata: {
    description: 'Virtual machine size'
  }
  default: 'Standard_A1_v2'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-dns-forwarder/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var ubuntuOSVersion = '18.04-LTS'
var asetName_var = 'dnsproxy-avail'
var nsgName_var = 'dnsproxy-nsg'
var vnetName_var = 'dnsproxy-vnet'
var vnetAddressPrefix = '10.0.0.0/8'
var subNet1Name = 'subnet1'
var subNet1Prefix = '10.1.0.0/16'
var storType = 'Standard_LRS'
var location_var = location
var nicName_var = '${vmName}-nic'
var pipName_var = '${vmName}-pip'
var scriptUrl = uri(artifactsLocation, 'forwarderSetup.sh${artifactsLocationSasToken}')
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

resource storageAccountName_res 'Microsoft.Storage/StorageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location_var
  sku: {
    name: storType
  }
  kind: 'StorageV2'
}

resource asetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: asetName_var
  location: location_var
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName_var
  location: location_var
  properties: {
    securityRules: [
      {
        name: 'allow_ssh_in'
        properties: {
          description: 'The only thing allowed is SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
  location: location_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subNet1Name
        properties: {
          addressPrefix: subNet1Prefix
        }
      }
    ]
  }
}

resource pipName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: pipName_var
  location: location_var
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
  location: location_var
  properties: {
    networkSecurityGroup: {
      id: nsgName.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subNet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location_var
  properties: {
    availabilitySet: {
      id: asetName.id
    }
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
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId('Microsoft.Storage/storageAccounts', toLower(storageAccountName))).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_res
  ]
}

resource vmName_setupdnsfirewall 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/setupdnsfirewall'
  location: location_var
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'sh forwarderSetup.sh ${forwardIP} ${vnetAddressPrefix}'
    }
  }
  dependsOn: [
    vmName_res
  ]
}
param vmAdminUsername string {
  metadata: {
    description: 'Admin username for the Virtual Machine.'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'Admin password for the Virtual Machine.'
  }
  secure: true
}
param vmDnsName string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the Virtual Machine.'
  }
  default: 'Standard_D2_v2'
}
param tentacleOctopusServerUrl string {
  metadata: {
    description: 'The URL of the Octopus Server with which to register.'
  }
}
param tentacleApiKey string {
  metadata: {
    description: 'The Api Key to use to register the Tentacle with the Octopus Server.'
  }
  secure: true
}
param tentacleCommunicationMode string {
  allowed: [
    'Listen'
    'Poll'
  ]
  metadata: {
    description: 'The type of Tentacle - whether the Tentacle listens for requests from the Octopus Server, or actively polls the Octopus Server for requests.'
  }
  default: 'Listen'
}
param tentaclePort int {
  minValue: 0
  maxValue: 65535
  metadata: {
    description: 'The port on which the Tentacle should listen, when CommunicationMode is set to Listen, or the port on which to poll the Octopus Server, when CommunicationMode is set to Poll. By default, Tentacle\'s listen on 10933 and polls the Octopus Server on 10943.'
  }
  default: 10933
}
param tentacleRoles string {
  metadata: {
    description: 'A comma delimited list of Roles to apply to the Tentacle.'
  }
}
param tentacleEnvironments string {
  metadata: {
    description: 'A comma delimited list of Environments in which the Tentacle should be placed.'
  }
}
param tentaclePublicHostNameConfiguration string {
  allowed: [
    'PublicIP'
    'FQDN'
    'ComputerName'
    'Custom'
  ]
  metadata: {
    description: 'How the Octopus Server should contact the Tentacle. Only required when CommunicationMode is \'Listen\'.'
  }
  default: 'PublicIP'
}
param tentacleCustomPublicHostName string {
  metadata: {
    description: 'The custom public host name that the Octopus Server should use to contact the Tentacle. Only required when communicationMode is \'Listen\' and publicHostNameConfiguration is \'Custom\'.'
  }
  default: ''
}

var namespace = 'octopus'
var location = resourceGroup().location
var tags = {
  vendor: 'Octopus Deploy'
  description: 'Example deployment of Octopus Tentacle to a Windows Server.'
}
var diagnostics = {
  storageAccount: {
    name: 'diagnostics${uniqueString(resourceGroup().id)}'
  }
}
var networkSecurityGroupName_var = '${namespace}-nsg'
var publicIPAddressName_var = '${namespace}-publicip'
var vnet = {
  name: '${namespace}-vnet'
  addressPrefix: '10.0.0.0/16'
  subnet: {
    name: '${namespace}-subnet'
    addressPrefix: '10.0.0.0/24'
  }
}
var nic = {
  name: '${namespace}-nic'
  ipConfigName: '${namespace}-ipconfig'
}
var vmName_var = '${namespace}-vm'

resource diagnostics_storageAccount_name 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: diagnostics.storageAccount.name
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: networkSecurityGroupName_var
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    securityRules: [
      {
        name: 'allow_rdp'
        properties: {
          description: 'Allow inbound RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource vnet_name 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: vnet.name
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnet.subnet.name
        properties: {
          addressPrefix: vnet.subnet.addressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nic_name 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: nic.name
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    ipConfigurations: [
      {
        name: nic.ipConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: '${vnet_name.id}/subnets/${vnet.subnet.name}'
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName_var
  location: location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_name.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${diagnostics.storageAccount.name}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    diagnostics_storageAccount_name
  ]
}

resource namespace_vm_OctopusDeployWindowsTentacle 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  name: '${namespace}-vm/OctopusDeployWindowsTentacle'
  location: resourceGroup().location
  tags: {
    vendor: tags.vendor
    description: tags.description
  }
  properties: {
    publisher: 'OctopusDeploy.Tentacle'
    type: 'OctopusDeployWindowsTentacle'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: 'true'
    settings: {
      OctopusServerUrl: tentacleOctopusServerUrl
      Environments: split(tentacleEnvironments, ',')
      Roles: split(tentacleRoles, ',')
      CommunicationMode: tentacleCommunicationMode
      Port: tentaclePort
      PublicHostNameConfiguration: tentaclePublicHostNameConfiguration
      CustomPublicHostName: tentacleCustomPublicHostName
    }
    protectedSettings: {
      ApiKey: tentacleApiKey
    }
  }
  dependsOn: [
    vmName
  ]
}

output vmFullyQualifiedDomainName string = reference('Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}').dnsSettings.fqdn
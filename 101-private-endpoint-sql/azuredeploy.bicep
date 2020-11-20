param sqlAdministratorLogin string {
  metadata: {
    description: 'The administrator username of the SQL logical server'
  }
}
param sqlAdministratorLoginPassword string {
  metadata: {
    description: 'The administrator password of the SQL logical server.'
  }
  secure: true
}
param vmAdminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine. The password must be at least 12 characters long and have lower case, upper characters, digit and a special character (Regex match)'
  }
  secure: true
}
param VmSize string {
  metadata: {
    description: 'The size of the VM'
  }
  default: 'Standard_D2_v2'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vnetName_var = 'myVirtualNetwork'
var vnetAddressPrefix = '10.0.0.0/16'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'mySubnet'
var sqlServerName_var = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName_var = '${sqlServerName_var}/sample-db'
var privateEndpointName_var = 'myPrivateEndpoint'
var privateDnsZoneName_var = 'privatelink${environment().suffixes.sqlServerHostname}'
var pvtendpointdnsgroupname_var = '${privateEndpointName_var}/mydnsgroupname'
var vmName_var = take('myVm${uniqueString(resourceGroup().id)}', 15)
var publicIpAddressName_var = '${vmName_var}PublicIP'
var networkInterfaceName_var = '${vmName_var}NetInt'
var osDiskType = 'Standard_LRS'

resource sqlServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName_var
  location: location
  kind: 'v12.0'
  tags: {
    displayName: sqlServerName_var
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: databaseName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: databaseName_var
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: 104857600
    requestedServiceObjectiveName: 'Basic'
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServerName
  ]
}

resource vnetName 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource vnetName_subnet1Name 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vnetName_var}/${subnet1Name}'
  location: location
  properties: {
    addressPrefix: subnet1Prefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    vnetName
  ]
}

resource privateEndpointName 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName_var
  location: location
  properties: {
    subnet: {
      id: vnetName_subnet1Name.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName_var
        properties: {
          privateLinkServiceId: sqlServerName.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource privateDnsZoneName 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: privateDnsZoneName_var
  location: 'global'
  properties: ''
  dependsOn: [
    vnetName
  ]
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  name: '${privateDnsZoneName_var}/${privateDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
  dependsOn: [
    privateDnsZoneName
  ]
}

resource pvtendpointdnsgroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: pvtendpointdnsgroupname_var
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneName.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointName
  ]
}

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpAddressName_var
  location: location
  tags: {
    displayName: publicIpAddressName_var
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(vmName_var)
    }
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName_var
  location: location
  tags: {
    displayName: networkInterfaceName_var
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
          subnet: {
            id: vnetName_subnet1Name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName_var
  location: location
  tags: {
    displayName: vmName_var
  }
  properties: {
    hardwareProfile: {
      vmSize: VmSize
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
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}
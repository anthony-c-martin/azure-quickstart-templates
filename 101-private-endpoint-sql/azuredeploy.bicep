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

var vnetName = 'myVirtualNetwork'
var vnetAddressPrefix = '10.0.0.0/16'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'mySubnet'
var sqlServerName = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName = '${sqlServerName}/sample-db'
var privateEndpointName = 'myPrivateEndpoint'
var privateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var pvtendpointdnsgroupname = '${privateEndpointName}/mydnsgroupname'
var vmName = take('myVm${uniqueString(resourceGroup().id)}', 15)
var publicIpAddressName = '${vmName}PublicIP'
var networkInterfaceName = '${vmName}NetInt'
var osDiskType = 'Standard_LRS'

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName
  location: location
  kind: 'v12.0'
  tags: {
    displayName: sqlServerName
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName_resource 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: databaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: databaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: 104857600
    requestedServiceObjectiveName: 'Basic'
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
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
  name: '${vnetName}/${subnet1Name}'
  location: location
  properties: {
    addressPrefix: subnet1Prefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: vnetName_subnet1Name.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServerName_resource.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    sqlServerName_resource
  ]
}

resource privateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: ''
  dependsOn: [
    vnetName_resource
  ]
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  name: '${privateDnsZoneName}/${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName_resource.id
    }
  }
  dependsOn: [
    privateDnsZoneName_resource
    vnetName_resource
  ]
}

resource pvtendpointdnsgroupname_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: pvtendpointdnsgroupname
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneName_resource.id
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZoneName_resource
    privateEndpointName_resource
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpAddressName
  location: location
  tags: {
    displayName: publicIpAddressName
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(vmName)
    }
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  tags: {
    displayName: networkInterfaceName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName_resource.id
          }
          subnet: {
            id: vnetName_subnet1Name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIpAddressName_resource
    vnetName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: {
    displayName: vmName
  }
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    osProfile: {
      computerName: vmName
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
        name: '${vmName}OsDisk'
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
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}
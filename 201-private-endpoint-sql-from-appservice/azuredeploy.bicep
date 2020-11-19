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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-private-endpoint-sql-from-appservice/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}

var vnetName_var = 'myVirtualNetwork'
var vnetAddressPrefix = '10.0.0.0/16'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'mySubnet'
var subnetAppServicePrefix = '10.0.1.0/24'
var subnetAppServiceName = 'subnetAppService'
var sqlServerName_var = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName_var = '${sqlServerName_var}/sample-db'
var privateEndpointName_var = 'myPrivateEndpoint'
var privateDnsZoneName_var = 'privatelink.database.windows.net'
var pvtendpointdnsgroupname_var = '${privateEndpointName_var}/mydnsgroupname'
var websitename_var = take('webapppvl${uniqueString(resourceGroup().id)}', 15)
var appServicePlanName_var = take('appSrvPln${uniqueString(resourceGroup().id)}', 15)

resource sqlServerName 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName_var
  location: location
  tags: {
    displayName: sqlServerName_var
  }
  kind: 'v12.0'
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName 'Microsoft.Sql/servers/databases@2019-06-01-preview' = {
  name: databaseName_var
  location: location
  tags: {
    displayName: databaseName_var
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: 104857600
    requestedServiceObjectiveName: 'Basic'
    sampleName: 'AdventureWorksLT'
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: subnetAppServiceName
        properties: {
          addressPrefix: subnetAppServicePrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource privateEndpointName 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: privateEndpointName_var
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet1Name)
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
}

resource privateDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName_var
  location: 'global'
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZoneName_var}/${privateDnsZoneName_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetName.id
    }
  }
}

resource pvtendpointdnsgroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
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
}

resource appServicePlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    name: 'P1v2'
    capacity: 1
  }
  tags: {
    displayName: appServicePlanName_var
  }
  properties: {
    name: appServicePlanName_var
  }
}

resource websitename 'Microsoft.Web/sites@2019-08-01' = {
  name: websitename_var
  location: location
  tags: {
    displayName: websitename_var
  }
  properties: {
    name: websitename_var
    serverFarmId: appServicePlanName.id
    siteConfig: {
      connectionStrings: [
        {
          name: 'sampledbContext'
          connectionString: 'Server=tcp:${reference(sqlServerName_var).fullyQualifiedDomainName},1433;Initial Catalog=sample-db;Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
      ]
    }
  }
}

resource websitename_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${websitename_var}/appsettings'
  tags: {
    displayName: 'WebAppSettings'
  }
  properties: {
    WEBSITE_VNET_ROUTE_ALL: '1'
    WEBSITE_DNS_SERVER: '168.63.129.16'
  }
}

resource websitename_MSDeploy 'Microsoft.Web/sites/extensions@2019-08-01' = {
  name: '${websitename_var}/MSDeploy'
  location: location
  tags: {
    displayName: 'Web Deploy for webapppvtlink'
  }
  properties: {
    packageUri: uri(artifactsLocation, 'artifacts/AdventureWorks.Web.zip${artifactsLocationSasToken}')
    dbType: 'None'
    setParameters: {
      'IIS Web Application Name': websitename_var
    }
  }
}

resource websitename_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  name: '${websitename_var}/virtualNetwork'
  location: location
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetAppServiceName)
    swiftSupported: true
  }
}
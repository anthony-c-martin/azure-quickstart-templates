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

var vnetName = 'myVirtualNetwork'
var vnetAddressPrefix = '10.0.0.0/16'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'mySubnet'
var subnetAppServicePrefix = '10.0.1.0/24'
var subnetAppServiceName = 'subnetAppService'
var sqlServerName = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName = '${sqlServerName}/sample-db'
var privateEndpointName = 'myPrivateEndpoint'
var privateDnsZoneName = 'privatelink.database.windows.net'
var pvtendpointdnsgroupname = '${privateEndpointName}/mydnsgroupname'
var websitename = take('webapppvl${uniqueString(resourceGroup().id)}', 15)
var appServicePlanName = take('appSrvPln${uniqueString(resourceGroup().id)}', 15)

resource sqlServerName_resource 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    displayName: sqlServerName
  }
  kind: 'v12.0'
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName_resource 'Microsoft.Sql/servers/databases@2019-06-01-preview' = {
  name: databaseName
  location: location
  tags: {
    displayName: databaseName
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
  dependsOn: [
    sqlServerName_resource
  ]
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: vnetName
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

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name)
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

resource privateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
  dependsOn: [
    vnetName_resource
  ]
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
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

resource pvtendpointdnsgroupname_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
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

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v2'
    capacity: 1
  }
  tags: {
    displayName: appServicePlanName
  }
  properties: {
    name: appServicePlanName
  }
}

resource websitename_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: websitename
  location: location
  tags: {
    displayName: websitename
  }
  properties: {
    name: websitename
    serverFarmId: appServicePlanName_resource.id
    siteConfig: {
      connectionStrings: [
        {
          name: 'sampledbContext'
          connectionString: 'Server=tcp:${reference(sqlServerName).fullyQualifiedDomainName},1433;Initial Catalog=sample-db;Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
      ]
    }
  }
  dependsOn: [
    appServicePlanName_resource
  ]
}

resource websitename_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${websitename}/appsettings'
  tags: {
    displayName: 'WebAppSettings'
  }
  properties: {
    WEBSITE_VNET_ROUTE_ALL: '1'
    WEBSITE_DNS_SERVER: '168.63.129.16'
  }
  dependsOn: [
    websitename_resource
    websitename_MSDeploy
  ]
}

resource websitename_MSDeploy 'Microsoft.Web/sites/extensions@2019-08-01' = {
  name: '${websitename}/MSDeploy'
  location: location
  tags: {
    displayName: 'Web Deploy for webapppvtlink'
  }
  properties: {
    packageUri: uri(artifactsLocation, 'artifacts/AdventureWorks.Web.zip${artifactsLocationSasToken}')
    dbType: 'None'
    setParameters: {
      'IIS Web Application Name': websitename
    }
  }
  dependsOn: [
    websitename_resource
  ]
}

resource websitename_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  name: '${websitename}/virtualNetwork'
  location: location
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetAppServiceName)
    swiftSupported: true
  }
  dependsOn: [
    websitename_resource
    websitename_MSDeploy
  ]
}
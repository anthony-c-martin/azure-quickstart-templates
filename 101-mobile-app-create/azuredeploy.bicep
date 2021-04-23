@description('The name of the mobile app that you wish to create.')
param appName string

@description('The settings of the existing hosting plan.')
param hostingPlanSettings object = {
  tier: 'Standard'
  skuName: 'S1'
  capacity: 0
}

@description('The account name to use for the database server administrator.')
param sqlServerAdminLogin string

@description('The password to use for the database server administrator.')
@secure()
param sqlServerAdminPassword string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('The type of database to create.')
param sqlDatabaseEdition string

@description('The database collation for governing the proper use of characters.')
param sqlDatabaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('The maximum size, in bytes, for the database')
param sqlDatabaseMaxSizeBytes string = '1073741824'

@description('Location for all resources.')
param location string = resourceGroup().location

var uniqueAppName_var = '${appName}-${uniqueString(resourceGroup().id)}'
var hostingPlanName_var = '${uniqueAppName_var}-plan'
var databaseServerName_var = '${uniqueAppName_var}-sqlserver'
var databaseName = '${uniqueAppName_var}-sqldb'
var notificationHubNamespace_var = '${uniqueAppName_var}-namespace'
var notificationHubName = '${uniqueAppName_var}-hub'

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: hostingPlanSettings.skuName
    tier: hostingPlanSettings.tier
    capacity: hostingPlanSettings.capacity
  }
  properties: {
    numberOfWorkers: 1
  }
}

resource uniqueAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: uniqueAppName_var
  location: location
  kind: 'mobileapp'
  properties: {
    name: uniqueAppName_var
    serverFarmId: hostingPlanName.id
  }
}

resource uniqueAppName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: uniqueAppName
  name: 'appsettings'
  properties: {
    MS_MobileServiceName: uniqueAppName_var
    MS_NotificationHubName: notificationHubName
  }
}

resource uniqueAppName_connectionstrings 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: uniqueAppName
  name: 'connectionstrings'
  properties: {
    MS_TableConnectionString: {
      value: 'Data Source=tcp:${databaseServerName.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${sqlServerAdminLogin}@${databaseServerName_var};Password=${sqlServerAdminPassword};'
      type: 'SQLServer'
    }
    MS_NotificationHubConnectionString: {
      value: listkeys(resourceId('Microsoft.NotificationHubs/namespaces/notificationHubs/authorizationRules', notificationHubNamespace_var, notificationHubName, 'DefaultFullSharedAccessSignature'), '2017-04-01').primaryConnectionString
      type: 'Custom'
    }
  }
  dependsOn: [
    notificationHubName
    databaseServerName_databaseName
  ]
}

resource uniqueAppName_Microsoft_Resources_SiteToHub 'Microsoft.Web/sites/providers/links@2019-08-01' = {
  name: '${uniqueAppName_var}/Microsoft.Resources/SiteToHub'
  properties: {
    targetId: resourceId('Microsoft.NotificationHubs/namespaces/NotificationHubs', notificationHubNamespace_var, notificationHubName)
  }
  dependsOn: [
    uniqueAppName
    notificationHubName
  ]
}

resource databaseServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: databaseServerName_var
  location: location
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
    version: '12.0'
  }
}

resource databaseServerName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: databaseServerName
  name: '${databaseName}'
  location: location
  properties: {
    edition: sqlDatabaseEdition
    collation: sqlDatabaseCollation
    maxSizeBytes: sqlDatabaseMaxSizeBytes
  }
}

resource databaseServerName_open 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  parent: databaseServerName
  location: location
  name: 'open'
  properties: {
    endIpAddress: '255.255.255.255'
    startIpAddress: '0.0.0.0'
  }
}

resource notificationHubNamespace 'Microsoft.NotificationHubs/namespaces@2017-04-01' = {
  name: notificationHubNamespace_var
  location: location
  properties: {
    region: location
    namespaceType: 'NotificationHub'
  }
}

resource notificationHubNamespace_uniqueAppName_hub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2017-04-01' = {
  parent: notificationHubNamespace
  name: '${uniqueAppName_var}-hub'
  location: location
  properties: {}
}
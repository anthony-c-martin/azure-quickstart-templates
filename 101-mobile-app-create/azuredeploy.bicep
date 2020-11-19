param appName string {
  metadata: {
    description: 'The name of the mobile app that you wish to create.'
  }
}
param hostingPlanSettings object {
  metadata: {
    description: 'The settings of the existing hosting plan.'
  }
  default: {
    tier: 'Standard'
    skuName: 'S1'
    capacity: 0
  }
}
param sqlServerAdminLogin string {
  metadata: {
    description: 'The account name to use for the database server administrator.'
  }
}
param sqlServerAdminPassword string {
  metadata: {
    description: 'The password to use for the database server administrator.'
  }
  secure: true
}
param sqlDatabaseEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The type of database to create.'
  }
}
param sqlDatabaseCollation string {
  metadata: {
    description: 'The database collation for governing the proper use of characters.'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param sqlDatabaseMaxSizeBytes string {
  metadata: {
    description: 'The maximum size, in bytes, for the database'
  }
  default: '1073741824'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var uniqueAppName = '${appName}-${uniqueString(resourceGroup().id)}'
var hostingPlanName = '${uniqueAppName}-plan'
var databaseServerName = '${uniqueAppName}-sqlserver'
var databaseName = '${uniqueAppName}-sqldb'
var notificationHubNamespace = '${uniqueAppName}-namespace'
var notificationHubName = '${uniqueAppName}-hub'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
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

resource uniqueAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: uniqueAppName
  location: location
  kind: 'mobileapp'
  properties: {
    name: uniqueAppName
    serverFarmId: hostingPlanName_resource.id
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource uniqueAppName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${uniqueAppName}/appsettings'
  properties: {
    MS_MobileServiceName: uniqueAppName
    MS_NotificationHubName: notificationHubName
  }
  dependsOn: [
    uniqueAppName_resource
  ]
}

resource uniqueAppName_connectionstrings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${uniqueAppName}/connectionstrings'
  properties: {
    MS_TableConnectionString: {
      value: 'Data Source=tcp:${databaseServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${sqlServerAdminLogin}@${databaseServerName};Password=${sqlServerAdminPassword};'
      type: 'SQLServer'
    }
    MS_NotificationHubConnectionString: {
      value: listkeys(resourceId('Microsoft.NotificationHubs/namespaces/notificationHubs/authorizationRules', notificationHubNamespace, notificationHubName, 'DefaultFullSharedAccessSignature'), '2017-04-01').primaryConnectionString
      type: 'Custom'
    }
  }
  dependsOn: [
    uniqueAppName_resource
    notificationHubName
    databaseServerName_databaseName
  ]
}

resource uniqueAppName_Microsoft_Resources_SiteToHub 'Microsoft.Web/sites/providers/links@2019-08-01' = {
  name: '${uniqueAppName}/Microsoft.Resources/SiteToHub'
  properties: {
    targetId: resourceId('Microsoft.NotificationHubs/namespaces/NotificationHubs', notificationHubNamespace, notificationHubName)
  }
  dependsOn: [
    uniqueAppName_resource
    notificationHubName
  ]
}

resource databaseServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: databaseServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
    version: '12.0'
  }
}

resource databaseServerName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${databaseServerName}/${databaseName}'
  location: location
  properties: {
    edition: sqlDatabaseEdition
    collation: sqlDatabaseCollation
    maxSizeBytes: sqlDatabaseMaxSizeBytes
  }
  dependsOn: [
    databaseServerName_resource
  ]
}

resource databaseServerName_open 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  location: location
  name: '${databaseServerName}/open'
  properties: {
    endIpAddress: '255.255.255.255'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    databaseServerName_resource
  ]
}

resource notificationHubNamespace_resource 'Microsoft.NotificationHubs/namespaces@2017-04-01' = {
  name: notificationHubNamespace
  location: location
  properties: {
    region: location
    namespaceType: 'NotificationHub'
  }
}

resource notificationHubNamespace_uniqueAppName_hub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2017-04-01' = {
  name: '${notificationHubNamespace}/${uniqueAppName}-hub'
  location: location
  properties: {}
  dependsOn: [
    notificationHubNamespace_resource
  ]
}
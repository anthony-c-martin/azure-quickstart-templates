param skuName string {
  allowed: [
    'F1'
    'D1'
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P4'
  ]
  metadata: {
    description: 'Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/'
  }
  default: 'F1'
}
param skuCapacity int {
  minValue: 1
  metadata: {
    description: 'Describes plan\'s instance count'
  }
  default: 1
}
param administratorLogin string {
  metadata: {
    description: 'The admin user of the SQL Server'
  }
}
param administratorLoginPassword string {
  metadata: {
    description: 'The password of the admin user of the SQL Server'
  }
  secure: true
}
param databaseName string {
  metadata: {
    description: 'The name of the new database to create.'
  }
}
param collation string {
  metadata: {
    description: 'The database collation for governing the proper use of characters.'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param edition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The type of database to create.'
  }
  default: 'Basic'
}
param maxSizeBytes string {
  metadata: {
    description: 'The maximum size, in bytes, for the database'
  }
  default: '1073741824'
}
param requestedServiceObjectiveName string {
  allowed: [
    'Basic'
    'S0'
    'S1'
    'S2'
    'P1'
    'P2'
    'P3'
  ]
  metadata: {
    description: 'Describes the performance level for Edition'
  }
  default: 'Basic'
}
param cacheSKUName string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The pricing tier of the new Azure Redis Cache.'
  }
  default: 'Basic'
}
param cacheSKUFamily string {
  allowed: [
    'C'
  ]
  metadata: {
    description: 'The family for the sku.'
  }
  default: 'C'
}
param cacheSKUCapacity int {
  allowed: [
    0
    1
    2
    3
    4
    5
    6
  ]
  metadata: {
    description: 'The size of the new Azure Redis Cache instance. '
  }
  default: 0
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var hostingPlanName = 'hostingplan${uniqueString(resourceGroup().id)}'
var webSiteName = 'webSite${uniqueString(resourceGroup().id)}'
var sqlserverName = 'sqlserver${uniqueString(resourceGroup().id)}'
var cacheName = 'cache${uniqueString(resourceGroup().id)}'

resource sqlserverName_resource 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlserverName
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
  }
}

resource sqlserverName_databaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlserverName}/${databaseName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: edition
    collation: collation
    maxSizeBytes: maxSizeBytes
    requestedServiceObjectiveName: requestedServiceObjectiveName
  }
  dependsOn: [
    sqlserverName_resource
  ]
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  location: location
  name: '${sqlserverName}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlserverName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: hostingPlanName
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName
  }
}

resource webSiteName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: webSiteName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'empty'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName
    serverFarmId: hostingPlanName_resource.id
  }
  dependsOn: [
    hostingPlanName_resource
    cacheName_resource
  ]
}

resource webSiteName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webSiteName}/connectionstrings'
  properties: {
    TeamContext: {
      value: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${sqlserverName}').fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${administratorLogin}@${sqlserverName};Password=${administratorLoginPassword};'
      type: 'SQLServer'
    }
  }
  dependsOn: [
    webSiteName_resource
    sqlserverName_resource
  ]
}

resource webSiteName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webSiteName}/appsettings'
  properties: {
    CacheConnection: '${cacheName}.redis.cache.windows.net,abortConnect=false,ssl=true,password=${listKeys(cacheName_resource.id, '2015-08-01').primaryKey}'
  }
  dependsOn: [
    webSiteName_resource
    cacheName_resource
  ]
}

resource cacheName_resource 'Microsoft.Cache/Redis@2015-08-01' = {
  name: cacheName
  location: location
  tags: {
    displayName: 'cache'
  }
  properties: {
    sku: {
      name: cacheSKUName
      family: cacheSKUFamily
      capacity: cacheSKUCapacity
    }
  }
  dependsOn: []
}
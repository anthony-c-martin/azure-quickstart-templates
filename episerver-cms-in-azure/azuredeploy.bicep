param WebApplicationWebAppName string {
  minLength: 1
  metadata: {
    description: 'Name of the WebApp Running EPiServer'
  }
  default: 'episervercmsapp${uniqueString(resourceGroup().id)}'
}
param WebApplication_HostingPlanNameName string {
  minLength: 1
  metadata: {
    description: 'Name of the App Service Hosting Plan'
  }
  default: 'hostingplan${uniqueString(resourceGroup().id)}'
}
param WebApplication_HostingPlanNameSKU string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Describes the pricing tier of the Hosting Plan'
  }
  default: 'Free'
}
param WebApplication_HostingPlanNameWorkerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'Describes the WorkerSize level of the Hosting Plan'
  }
  default: '0'
}
param StorageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_ZRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Describes the Storage Account Type'
  }
  default: 'Standard_LRS'
}
param StorageAccountName string {
  metadata: {
    description: 'Name of the Storage Account'
  }
  default: 'epistorage${uniqueString(resourceGroup().id)}'
}
param sqlserverName string {
  metadata: {
    description: 'Name of the Sql Server'
  }
  default: 'sqlserver${uniqueString(resourceGroup().id)}'
}
param sqlserverAdminLogin string {
  minLength: 1
  metadata: {
    description: 'Name of the Sql Admin Account'
  }
}
param sqlserverAdminLoginPassword string {
  metadata: {
    description: 'Password of the Sql Admin Account'
  }
  secure: true
}
param SQL_DatabaseName string {
  minLength: 1
  metadata: {
    description: 'Name of the Sql Database'
  }
  default: 'episerverdb'
}
param SQL_DatabaseCollation string {
  minLength: 1
  metadata: {
    description: 'Describes the performance level for SQL Databse Collation'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param SQL_DatabaseEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Describes the performance level for SQL Database Edition'
  }
  default: 'Basic'
}
param SQL_DatabaseRequestedServiceObjectiveName string {
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
param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
  }
}
param serviceBusSku string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The messaging tier for service Bus namespace'
  }
  default: 'Standard'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var location_variable = location
var defaultSASKeyName = 'RootManageSharedAccessKey'
var defaultAuthRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, defaultSASKeyName)
var storageAccountApiVersion = '2015-06-15'
var serviceBusApiVersion = '2015-08-01'
var storageId = StorageAccountName_resource.id
var storageConnectionStringPrefix = 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey='

resource WebApplication_HostingPlanNameName_resource 'Microsoft.Web/serverfarms@2014-06-01' = {
  name: WebApplication_HostingPlanNameName
  location: location
  tags: {
    displayName: 'WebApplication-HostingPlanName'
  }
  properties: {
    name: WebApplication_HostingPlanNameName
    sku: WebApplication_HostingPlanNameSKU
    workerSize: WebApplication_HostingPlanNameWorkerSize
    numberOfWorkers: 1
  }
}

resource WebApplicationWebAppName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: WebApplicationWebAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${WebApplication_HostingPlanNameName}': 'Resource'
    displayName: 'WebApplication-WebApp'
  }
  properties: {
    name: WebApplicationWebAppName
    serverFarmId: WebApplication_HostingPlanNameName_resource.id
    webSocketsEnabled: true
    alwaysOn: false
  }
  dependsOn: [
    WebApplication_HostingPlanNameName_resource
    StorageAccountName_resource
    sqlserverName_resource
    serviceBusNamespaceName_resource
  ]
}

resource WebApplicationWebAppName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${WebApplicationWebAppName}/connectionstrings'
  tags: {
    displayName: 'WebApplication-WebApp-ConnectionStrings'
  }
  properties: {
    EPiServerAzureBlobs: {
      value: concat(storageConnectionStringPrefix, listkeys(storageId, storageAccountApiVersion).key1)
      type: 'Custom'
    }
    EPiServerAzureEvents: {
      value: listkeys(defaultAuthRuleResourceId, serviceBusApiVersion).primaryConnectionString
      type: 'Custom'
    }
    EPiServerDB: {
      value: 'Server=tcp:${reference('Microsoft.Sql/servers/${sqlserverName}').fullyQualifiedDomainName},1433;Initial Catalog=${SQL_DatabaseName};User Id=${sqlserverAdminLogin}@${sqlserverName};Password=${sqlserverAdminLoginPassword};Trusted_Connection=False;Encrypt=True;Connection Timeout=30;MultipleActiveResultSets=True'
      type: 'SQLAzure'
    }
  }
  dependsOn: [
    WebApplicationWebAppName_resource
  ]
}

resource WebApplicationWebAppName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${WebApplicationWebAppName}/appsettings'
  tags: {
    displayName: 'WebApplication-WebApp-ApplicationSettings'
  }
  properties: {
    'episerver:ReadOnlyConfigurationAPI': 'True'
  }
  dependsOn: [
    WebApplicationWebAppName_resource
  ]
}

resource WebApplicationWebAppName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${WebApplicationWebAppName}/web'
  tags: {
    displayName: 'WebApplication-WebApp-GeneralSettings'
  }
  properties: {
    webSocketsEnabled: 'True'
    alwaysOn: 'True'
  }
  dependsOn: [
    WebApplicationWebAppName_resource
  ]
}

resource StorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: StorageAccountName
  location: location
  tags: {
    displayName: 'StorageAccount'
  }
  properties: {
    accountType: StorageAccountType
  }
}

resource sqlserverName_resource 'Microsoft.Sql/servers@2014-04-01' = {
  location: location
  name: sqlserverName
  properties: {
    administratorLogin: sqlserverAdminLogin
    administratorLoginPassword: sqlserverAdminLoginPassword
    version: '12.0'
  }
  tags: {
    displayName: 'SQL-Server'
  }
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01' = {
  name: '${sqlserverName}/AllowAllWindowsAzureIps'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlserverName_resource
  ]
}

resource sqlserverName_SQL_DatabaseName 'Microsoft.Sql/servers/databases@2014-04-01' = {
  name: '${sqlserverName}/${SQL_DatabaseName}'
  location: location
  tags: {
    displayName: 'SQL-Database'
  }
  properties: {
    collation: SQL_DatabaseCollation
    edition: SQL_DatabaseEdition
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: SQL_DatabaseRequestedServiceObjectiveName
  }
  dependsOn: [
    sqlserverName_resource
  ]
}

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2015-08-01' = {
  name: serviceBusNamespaceName
  location: location_variable
  kind: 'Messaging'
  tags: {
    displayName: 'ServiceBus'
  }
  sku: {
    name: serviceBusSku
    tier: serviceBusSku
  }
}
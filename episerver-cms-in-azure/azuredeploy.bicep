@minLength(1)
@description('Name of the WebApp Running EPiServer')
param WebApplicationWebAppName string = 'episervercmsapp${uniqueString(resourceGroup().id)}'

@minLength(1)
@description('Name of the App Service Hosting Plan')
param WebApplication_HostingPlanNameName string = 'hostingplan${uniqueString(resourceGroup().id)}'

@allowed([
  'Free'
  'Shared'
  'Basic'
  'Standard'
  'Premium'
])
@description('Describes the pricing tier of the Hosting Plan')
param WebApplication_HostingPlanNameSKU string = 'Free'

@allowed([
  '0'
  '1'
  '2'
])
@description('Describes the WorkerSize level of the Hosting Plan')
param WebApplication_HostingPlanNameWorkerSize string = '0'

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Describes the Storage Account Type')
param StorageAccountType string = 'Standard_LRS'

@description('Name of the Storage Account')
param StorageAccountName string = 'epistorage${uniqueString(resourceGroup().id)}'

@description('Name of the Sql Server')
param sqlserverName string = 'sqlserver${uniqueString(resourceGroup().id)}'

@minLength(1)
@description('Name of the Sql Admin Account')
param sqlserverAdminLogin string

@description('Password of the Sql Admin Account')
@secure()
param sqlserverAdminLoginPassword string

@minLength(1)
@description('Name of the Sql Database')
param SQL_DatabaseName string = 'episerverdb'

@minLength(1)
@description('Describes the performance level for SQL Databse Collation')
param SQL_DatabaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Describes the performance level for SQL Database Edition')
param SQL_DatabaseEdition string = 'Basic'

@allowed([
  'Basic'
  'S0'
  'S1'
  'S2'
  'P1'
  'P2'
  'P3'
])
@description('Describes the performance level for Edition')
param SQL_DatabaseRequestedServiceObjectiveName string = 'Basic'

@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@allowed([
  'Basic'
  'Standard'
])
@description('The messaging tier for service Bus namespace')
param serviceBusSku string = 'Standard'

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
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
    StorageAccountName_resource
    sqlserverName_resource
    serviceBusNamespaceName_resource
  ]
}

resource WebApplicationWebAppName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: WebApplicationWebAppName_resource
  name: 'connectionstrings'
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
}

resource WebApplicationWebAppName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: WebApplicationWebAppName_resource
  name: 'appsettings'
  tags: {
    displayName: 'WebApplication-WebApp-ApplicationSettings'
  }
  properties: {
    'episerver:ReadOnlyConfigurationAPI': 'True'
  }
}

resource WebApplicationWebAppName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: WebApplicationWebAppName_resource
  name: 'web'
  tags: {
    displayName: 'WebApplication-WebApp-GeneralSettings'
  }
  properties: {
    webSocketsEnabled: 'True'
    alwaysOn: 'True'
  }
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
  parent: sqlserverName_resource
  name: 'AllowAllWindowsAzureIps'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlserverName_SQL_DatabaseName 'Microsoft.Sql/servers/databases@2014-04-01' = {
  parent: sqlserverName_resource
  name: '${SQL_DatabaseName}'
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
}

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2015-08-01' = {
  name: serviceBusNamespaceName
  location: location_var
  kind: 'Messaging'
  tags: {
    displayName: 'ServiceBus'
  }
  sku: {
    name: serviceBusSku
    tier: serviceBusSku
  }
}
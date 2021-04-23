@minLength(3)
@description('The Azure Cosmos DB database account name.')
param databaseAccountName string

@allowed([
  'Eventual'
  'Strong'
  'Session'
  'BoundedStaleness'
])
@description('The Azure Cosmos DB default consistency level for this account.')
param consistencyLevel string = 'Session'

@minValue(10)
@maxValue(1000)
@description('When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.')
param maxStalenessPrefix int = 10

@minValue(5)
@maxValue(600)
@description('When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.')
param maxIntervalInSeconds int = 5

@minLength(1)
@description('The SQL server admin username.')
param sqlServerAdminLogin string

@description('The SQL server admin password')
@secure()
param sqlServerAdminLoginPassword string

@minLength(1)
@description('The SQL database name')
param sqlDatabaseName string

@minLength(1)
@description('The SQL database collation')
param sqlDatabaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('The SQL server edition')
param sqlDatabaseEdition string = 'Basic'

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
param sqldatabaseRequestedServiceObjectiveName string = 'Basic'

@minLength(1)
@description('The name of the Web App')
param webAppName string

@allowed([
  'Free'
  'Shared'
  'Basic'
  'Standard'
])
@description('The Web App pricing tier')
param webAppSKU string = 'Free'

@allowed([
  '0'
  '1'
  '2'
])
@description('The Web App worker size')
param workerSize string = '0'

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('The storage account type')
param storageAccountType string = 'Standard_LRS'

@description('The azure search instance name')
param azureSearchname string

@allowed([
  'free'
  'standard'
  'standard2'
])
@description('The azure search instance tier.')
param azureSearchSku string = 'free'

@allowed([
  1
  2
  3
  4
  5
  6
])
@description('The number of search replicas')
param azureSearchReplicaCount int = 1

@allowed([
  1
  2
  3
  4
  6
  12
])
@description('The number of search partitions')
param azureSearchPartitionCount int = 1

@allowed([
  'Standard'
])
@description('The Azure Cosmos DB offer type')
param documentDBOfferType string = 'Standard'

@description('Location for all resources.')
param location string = resourceGroup().location

var sqlServerName_var = '${uniqueString(resourceGroup().id)}sqlserver'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'

resource databaseAccountName_resource 'Microsoft.DocumentDB/databaseAccounts@2015-04-08' = {
  name: databaseAccountName
  location: location
  tags: {
    displayName: 'DocumentDB'
  }
  properties: {
    name: databaseAccountName
    databaseAccountOfferType: documentDBOfferType
    consistencyPolicy: {
      defaultConsistencyLevel: consistencyLevel
      maxStalenessPrefix: maxStalenessPrefix
      maxIntervalInSeconds: maxIntervalInSeconds
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

resource sqlServerName 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlServerName_var
  location: location
  tags: {
    displayName: 'SQL Server'
  }
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminLoginPassword
    version: '12.0'
  }
  dependsOn: []
}

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  parent: sqlServerName
  name: 'AllowAllWindowsAzureIps'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  parent: sqlServerName
  name: '${sqlDatabaseName}'
  location: location
  tags: {
    displayName: 'SQL Database'
  }
  properties: {
    collation: sqlDatabaseCollation
    edition: sqlDatabaseEdition
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: sqldatabaseRequestedServiceObjectiveName
  }
}

resource webAppName_resource 'Microsoft.Web/serverfarms@2014-06-01' = {
  name: webAppName
  location: location
  tags: {
    displayName: 'App Service Plan'
  }
  properties: {
    name: webAppName
    sku: webAppSKU
    workerSize: workerSize
    numberOfWorkers: 1
  }
  dependsOn: []
}

resource Microsoft_Web_sites_webAppName 'Microsoft.Web/sites@2015-08-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${webAppName}': 'Resource'
    displayName: 'Web App'
  }
  properties: {
    name: webAppName
    serverFarmId: webAppName_resource.id
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  tags: {
    displayName: 'Storage Account'
  }
  properties: {
    accountType: storageAccountType
  }
  dependsOn: []
}

resource azureSearchname_resource 'Microsoft.Search/searchServices@2015-02-28' = {
  name: azureSearchname
  location: location
  tags: {
    displayName: 'Azure Search'
  }
  properties: {
    sku: {
      name: azureSearchSku
    }
    replicaCount: azureSearchReplicaCount
    partitionCount: azureSearchPartitionCount
  }
}

resource appinsights 'Microsoft.Insights/components@2014-04-01' = {
  name: 'appinsights'
  location: 'Central US'
  tags: {
    displayName: 'Application Insights'
  }
  properties: {
    applicationId: webAppName
  }
  dependsOn: [
    Microsoft_Web_sites_webAppName
  ]
}
param databaseAccountName string {
  minLength: 3
  metadata: {
    description: 'The Azure Cosmos DB database account name.'
  }
}
param consistencyLevel string {
  allowed: [
    'Eventual'
    'Strong'
    'Session'
    'BoundedStaleness'
  ]
  metadata: {
    description: 'The Azure Cosmos DB default consistency level for this account.'
  }
  default: 'Session'
}
param maxStalenessPrefix int {
  minValue: 10
  maxValue: 1000
  metadata: {
    description: 'When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.'
  }
  default: 10
}
param maxIntervalInSeconds int {
  minValue: 5
  maxValue: 600
  metadata: {
    description: 'When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.'
  }
  default: 5
}
param sqlServerAdminLogin string {
  minLength: 1
  metadata: {
    description: 'The SQL server admin username.'
  }
}
param sqlServerAdminLoginPassword string {
  metadata: {
    description: 'The SQL server admin password'
  }
  secure: true
}
param sqlDatabaseName string {
  minLength: 1
  metadata: {
    description: 'The SQL database name'
  }
}
param sqlDatabaseCollation string {
  minLength: 1
  metadata: {
    description: 'The SQL database collation'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param sqlDatabaseEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The SQL server edition'
  }
  default: 'Basic'
}
param sqldatabaseRequestedServiceObjectiveName string {
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
param webAppName string {
  minLength: 1
  metadata: {
    description: 'The name of the Web App'
  }
}
param webAppSKU string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The Web App pricing tier'
  }
  default: 'Free'
}
param workerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'The Web App worker size'
  }
  default: '0'
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_ZRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'The storage account type'
  }
  default: 'Standard_LRS'
}
param azureSearchname string {
  metadata: {
    description: 'The azure search instance name'
  }
}
param azureSearchSku string {
  allowed: [
    'free'
    'standard'
    'standard2'
  ]
  metadata: {
    description: 'The azure search instance tier.'
  }
  default: 'free'
}
param azureSearchReplicaCount int {
  allowed: [
    1
    2
    3
    4
    5
    6
  ]
  metadata: {
    description: 'The number of search replicas'
  }
  default: 1
}
param azureSearchPartitionCount int {
  allowed: [
    1
    2
    3
    4
    6
    12
  ]
  metadata: {
    description: 'The number of search partitions'
  }
  default: 1
}
param documentDBOfferType string {
  allowed: [
    'Standard'
  ]
  metadata: {
    description: 'The Azure Cosmos DB offer type'
  }
  default: 'Standard'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var sqlServerName_var = '${uniqueString(resourceGroup().id)}sqlserver'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'

resource databaseAccountName_res 'Microsoft.DocumentDB/databaseAccounts@2015-04-08' = {
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
  name: '${sqlServerName_var}/AllowAllWindowsAzureIps'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlServerName_var}/${sqlDatabaseName}'
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

resource webAppName_res 'Microsoft.Web/serverfarms@2014-06-01' = {
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
    serverFarmId: webAppName_res.id
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

resource azureSearchname_res 'Microsoft.Search/searchServices@2015-02-28' = {
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
}
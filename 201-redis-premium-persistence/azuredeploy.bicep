@description('The name of the Azure Redis Cache to create.')
param redisCacheName string

@description('The location of the Redis Cache. For best performance, use the same location as the app to be used with the cache.')
param location string = resourceGroup().location

@allowed([
  1
  2
  3
  4
])
@description('The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).')
param redisCacheCapacity int = 1

@description('Name of an existing storage account for diagnostics. Must be in the same subscription and region.')
param existingDiagnosticsStorageAccountName string

@description('Name of an existing storage account to be cached.')
param storageAccountName string

@description('ResourceGroup for the storageAccount being cached.')
param storageAccountResourceGroup string

@description('Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).')
param enableNonSslPort bool = false

resource redisCacheName_resource 'Microsoft.Cache/Redis@2019-07-01' = {
  name: redisCacheName
  location: location
  properties: {
    enableNonSslPort: enableNonSslPort
    sku: {
      capacity: redisCacheCapacity
      family: 'P'
      name: 'Premium'
    }
    redisConfiguration: {
      'rdb-backup-enabled': 'true'
      'rdb-backup-frequency': '60'
      'rdb-storage-connection-string': 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId(storageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value}'
    }
  }
}

resource redisCacheName_Microsoft_Insights_service 'Microsoft.Cache/redis/providers/diagnosticsettings@2017-05-01-preview' = {
  name: '${redisCacheName}/Microsoft.Insights/service'
  location: location
  properties: {
    status: 'ON'
    storageAccountName: existingDiagnosticsStorageAccountName
  }
  dependsOn: [
    redisCacheName_resource
  ]
}
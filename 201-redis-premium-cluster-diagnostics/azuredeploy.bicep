@description('The name of the Azure Redis Cache to create.')
param redisCacheName string

@description('The location of the Redis Cache. For best performance, use the same location as the app to be used with the cache.')
param redisCacheLocation string

@description('Number of highly available shards to create in the cluster. Requires Premium SKU.')
param redisShardCount int

@allowed([
  1
  2
  3
  4
])
@description('The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).')
param redisCacheCapacity int = 1

@description('Name of an existing storage account for diagnostics. Must be in the same subscription.')
param existingDiagnosticsStorageAccountName string

@description('Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).')
param enableNonSslPort bool = false

resource redisCacheName_resource 'Microsoft.Cache/Redis@2015-08-01' = {
  name: redisCacheName
  location: redisCacheLocation
  properties: {
    enableNonSslPort: enableNonSslPort
    shardCount: redisShardCount
    sku: {
      capacity: redisCacheCapacity
      family: 'P'
      name: 'Premium'
    }
  }
}

resource redisCacheName_Microsoft_Insights_service 'Microsoft.Cache/redis/providers/diagnosticsettings@2015-07-01' = {
  name: '${redisCacheName}/Microsoft.Insights/service'
  location: redisCacheLocation
  properties: {
    status: 'ON'
    storageAccountName: existingDiagnosticsStorageAccountName
  }
  dependsOn: [
    redisCacheName_resource
  ]
}
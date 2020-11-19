param redisCacheName string {
  metadata: {
    description: 'The name of the Azure Redis Cache to create.'
  }
}
param redisCacheLocation string {
  metadata: {
    description: 'The location of the Redis Cache. For best performance, use the same location as the app to be used with the cache.'
  }
}
param redisShardCount int {
  metadata: {
    description: 'Number of highly available shards to create in the cluster. Requires Premium SKU.'
  }
}
param redisCacheCapacity int {
  allowed: [
    1
    2
    3
    4
  ]
  metadata: {
    description: 'The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).'
  }
  default: 1
}
param existingDiagnosticsStorageAccountName string {
  metadata: {
    description: 'Name of an existing storage account for diagnostics. Must be in the same subscription.'
  }
}
param enableNonSslPort bool {
  metadata: {
    description: 'Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).'
  }
  default: false
}

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
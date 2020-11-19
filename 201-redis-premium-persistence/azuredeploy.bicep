param redisCacheName string {
  metadata: {
    description: 'The name of the Azure Redis Cache to create.'
  }
}
param location string {
  metadata: {
    description: 'The location of the Redis Cache. For best performance, use the same location as the app to be used with the cache.'
  }
  default: resourceGroup().location
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
    description: 'Name of an existing storage account for diagnostics. Must be in the same subscription and region.'
  }
}
param storageAccountName string {
  metadata: {
    description: 'Name of an existing storage account to be cached.'
  }
}
param storageAccountResourceGroup string {
  metadata: {
    description: 'ResourceGroup for the storageAccount being cached.'
  }
}
param enableNonSslPort bool {
  metadata: {
    description: 'Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).'
  }
  default: false
}

resource redisCacheName_res 'Microsoft.Cache/Redis@2019-07-01' = {
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
}
param redisCacheName string {
  metadata: {
    description: 'Specify the name of the Azure Redis Cache to create.'
  }
}
param location string {
  metadata: {
    description: 'Location of all resources'
  }
  default: resourceGroup().location
}
param redisCacheSKU string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Specify the pricing tier of the new Azure Redis Cache.'
  }
  default: 'Standard'
}
param redisCacheFamily string {
  allowed: [
    'C'
    'P'
  ]
  metadata: {
    description: 'Specify the family for the sku. C = Basic/Standard, P = Premium.'
  }
  default: 'C'
}
param redisCacheCapacity int {
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
    description: 'Specify the size of the new Azure Redis Cache instance. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4)'
  }
  default: 1
}
param enableNonSslPort bool {
  metadata: {
    description: 'Specify a boolean value that indicates whether to allow access via non-SSL ports.'
  }
  default: false
}
param diagnosticsEnabled bool {
  metadata: {
    description: 'Specify a boolean value that indicates whether diagnostics should be saved to the specified storage account.'
  }
  default: false
}
param existingDiagnosticsStorageAccountId string {
  metadata: {
    description: 'Specify an existing storage account for diagnostics.'
  }
}

resource redisCacheName_res 'Microsoft.Cache/Redis@2020-06-01' = {
  name: redisCacheName
  location: location
  properties: {
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: '1.2'
    sku: {
      capacity: redisCacheCapacity
      family: redisCacheFamily
      name: redisCacheSKU
    }
  }
}

resource redisCacheName_Microsoft_Insights_redisCacheName 'Microsoft.Cache/redis/providers/diagnosticsettings@2017-05-01-preview' = {
  name: '${redisCacheName}/Microsoft.Insights/${redisCacheName}'
  location: location
  properties: {
    storageAccountId: existingDiagnosticsStorageAccountId
    metrics: [
      {
        timeGrain: 'AllMetrics'
        enabled: diagnosticsEnabled
        retentionPolicy: {
          days: 90
          enabled: diagnosticsEnabled
        }
      }
    ]
  }
}
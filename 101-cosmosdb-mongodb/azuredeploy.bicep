param accountName string {
  metadata: {
    description: 'Cosmos DB account name'
  }
  default: 'mongodb-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for the Cosmos DB account.'
  }
  default: resourceGroup().location
}
param primaryRegion string {
  metadata: {
    description: 'The primary replica region for the Cosmos DB account.'
  }
}
param secondaryRegion string {
  metadata: {
    description: 'The secondary replica region for the Cosmos DB account.'
  }
}
param defaultConsistencyLevel string {
  allowed: [
    'Eventual'
    'ConsistentPrefix'
    'Session'
    'BoundedStaleness'
    'Strong'
  ]
  metadata: {
    description: 'The default consistency level of the Cosmos DB account.'
  }
  default: 'Session'
}
param serverVersion string {
  allowed: [
    '3.2'
    '3.6'
  ]
  metadata: {
    description: 'Specifies the MongoDB server version to use.'
  }
  default: '3.6'
}
param maxStalenessPrefix int {
  minValue: 10
  maxValue: 2147483647
  metadata: {
    description: 'Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.'
  }
  default: 100000
}
param maxIntervalInSeconds int {
  minValue: 5
  maxValue: 86400
  metadata: {
    description: 'Max lag time (seconds). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.'
  }
  default: 300
}
param databaseName string {
  metadata: {
    description: 'The name for the Mongo DB database'
  }
}
param throughput int {
  minValue: 400
  maxValue: 1000000
  metadata: {
    description: 'The shared throughput for the Mongo DB database'
  }
  default: 400
}
param collection1Name string {
  metadata: {
    description: 'The name for the first Mongo DB collection'
  }
}
param collection2Name string {
  metadata: {
    description: 'The name for the second Mongo DB collection'
  }
}

var accountName_var = toLower(accountName)
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource accountName_res 'Microsoft.DocumentDB/databaseAccounts@2020-03-01' = {
  name: accountName_var
  location: location
  kind: 'MongoDB'
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    apiProperties: {
      serverVersion: serverVersion
    }
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2020-03-01' = {
  name: '${accountName_var}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: throughput
    }
  }
  dependsOn: [
    accountName_res
  ]
}

resource accountName_databaseName_collection1Name 'Microsoft.DocumentDb/databaseAccounts/mongodbDatabases/collections@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${collection1Name}'
  properties: {
    resource: {
      id: collection1Name
      shardKey: {
        user_id: 'Hash'
      }
      indexes: [
        {
          key: {
            keys: [
              'user_id'
              'user_address'
            ]
          }
          options: {
            unique: 'true'
          }
        }
        {
          key: {
            keys: [
              '_ts'
            ]
          }
          options: {
            expireAfterSeconds: '2629746'
          }
        }
      ]
      options: {
        'If-Match': '<ETag>'
      }
    }
  }
  dependsOn: [
    accountName_databaseName
  ]
}

resource accountName_databaseName_collection2Name 'Microsoft.DocumentDb/databaseAccounts/mongodbDatabases/collections@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${collection2Name}'
  properties: {
    resource: {
      id: collection2Name
      shardKey: {
        company_id: 'Hash'
      }
      indexes: [
        {
          key: {
            keys: [
              'company_id'
              'company_address'
            ]
          }
          options: {
            unique: 'true'
          }
        }
        {
          key: {
            keys: [
              '_ts'
            ]
          }
          options: {
            expireAfterSeconds: '2629746'
          }
        }
      ]
      options: {
        'If-Match': '<ETag>'
      }
    }
  }
  dependsOn: [
    accountName_databaseName
  ]
}
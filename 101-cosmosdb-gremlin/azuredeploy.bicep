param accountName string {
  metadata: {
    description: 'Cosmos DB account name'
  }
  default: uniqueString(resourceGroup().id)
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
param automaticFailover bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Enable automatic failover for regions'
  }
  default: true
}
param databaseName string {
  metadata: {
    description: 'The name for the Gremlin database'
  }
  default: 'database1'
}
param graphName string {
  metadata: {
    description: 'The name for the Gremlin graph'
  }
  default: 'graph1'
}
param throughput int {
  minValue: 400
  maxValue: 1000000
  metadata: {
    description: 'Throughput for the Gremlin graph'
  }
  default: 400
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
  kind: 'GlobalDocumentDB'
  properties: {
    capabilities: [
      {
        name: 'EnableGremlin'
      }
    ]
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2020-03-01' = {
  name: '${accountName_var}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_graphName 'Microsoft.DocumentDb/databaseAccounts/gremlinDatabases/graphs@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${graphName}'
  properties: {
    resource: {
      id: graphName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
      options: {
        throughput: throughput
      }
    }
  }
}
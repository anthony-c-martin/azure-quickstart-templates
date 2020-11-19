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
param api string {
  allowed: [
    'Sql'
    'MongoDB'
    'Cassandra'
    'Gremlin'
    'Table'
  ]
  metadata: {
    description: 'Cosmos DB account type.'
  }
  default: 'Sql'
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
param multipleWriteLocations bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Enable multi-master to make all regions writable.'
  }
  default: false
}
param automaticFailover bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Enable automatic failover for regions. Ignored when Multi-Master is enabled'
  }
  default: true
}

var accountName_variable = toLower(accountName)
var apiType = {
  Sql: {
    kind: 'GlobalDocumentDB'
    capabilities: []
  }
  MongoDB: {
    kind: 'MongoDB'
    capabilities: []
  }
  Cassandra: {
    kind: 'GlobalDocumentDB'
    capabilities: [
      {
        name: 'EnableCassandra'
      }
    ]
  }
  Gremlin: {
    kind: 'GlobalDocumentDB'
    capabilities: [
      {
        name: 'EnableGremlin'
      }
    ]
  }
  Table: {
    kind: 'GlobalDocumentDB'
    capabilities: [
      {
        name: 'EnableTable'
      }
    ]
  }
}
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

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: accountName_variable
  location: location
  kind: apiType[api].kind
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
    capabilities: apiType[api].capabilities
    enableMultipleWriteLocations: multipleWriteLocations
  }
}
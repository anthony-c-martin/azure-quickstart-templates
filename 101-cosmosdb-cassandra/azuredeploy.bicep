param accountName string {
  metadata: {
    description: 'Cosmos DB account name, max length 44 characters'
  }
  default: 'sql-${uniqueString(resourceGroup().id)}'
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
param keyspaceName string {
  metadata: {
    description: 'The name for the Cassandra Keyspace'
  }
}
param tableName string {
  metadata: {
    description: 'The name for the first Cassandra table'
  }
}
param throughput int {
  minValue: 400
  maxValue: 1000000
  metadata: {
    description: 'The throughput for both Cassandra tables'
  }
  default: 400
}

var accountName_variable = toLower(accountName)
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

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2020-03-01' = {
  name: accountName_variable
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    capabilities: [
      {
        name: 'EnableCassandra'
      }
    ]
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
  }
}

resource accountName_keyspaceName 'Microsoft.DocumentDB/databaseAccounts/cassandraKeyspaces@2020-03-01' = {
  name: '${accountName_variable}/${keyspaceName}'
  properties: {
    resource: {
      id: keyspaceName
    }
  }
  dependsOn: [
    accountName_resource
  ]
}

resource accountName_keyspaceName_tableName 'Microsoft.DocumentDb/databaseAccounts/cassandraKeyspaces/tables@2020-03-01' = {
  name: '${accountName_variable}/${keyspaceName}/${tableName}'
  properties: {
    resource: {
      id: tableName
      schema: {
        columns: [
          {
            name: 'loadid'
            type: 'uuid'
          }
          {
            name: 'machine'
            type: 'uuid'
          }
          {
            name: 'cpu'
            type: 'int'
          }
          {
            name: 'mtime'
            type: 'int'
          }
          {
            name: 'load'
            type: 'float'
          }
        ]
        partitionKeys: [
          {
            name: 'machine'
          }
          {
            name: 'cpu'
          }
          {
            name: 'mtime'
          }
        ]
        clusterKeys: [
          {
            name: 'loadid'
            orderBy: 'asc'
          }
        ]
      }
      options: {
        throughput: throughput
      }
    }
  }
  dependsOn: [
    accountName_keyspaceName
  ]
}
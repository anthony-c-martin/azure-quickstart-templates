@description('Cosmos DB account name')
param accountName string = uniqueString(resourceGroup().id)

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The primary replica region for the Cosmos DB account.')
param primaryRegion string

@description('The secondary replica region for the Cosmos DB account.')
param secondaryRegion string

@allowed([
  'Sql'
  'MongoDB'
  'Cassandra'
  'Gremlin'
  'Table'
])
@description('Cosmos DB account type.')
param api string = 'Sql'

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@minValue(10)
@maxValue(2147483647)
@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Max lag time (seconds). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@allowed([
  true
  false
])
@description('Enable multi-master to make all regions writable.')
param multipleWriteLocations bool = false

@allowed([
  true
  false
])
@description('Enable automatic failover for regions. Ignored when Multi-Master is enabled')
param automaticFailover bool = true

var accountName_var = toLower(accountName)
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
  name: accountName_var
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
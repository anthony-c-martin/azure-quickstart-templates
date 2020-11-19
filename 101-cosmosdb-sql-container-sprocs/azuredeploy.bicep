param accountName string {
  metadata: {
    description: 'Cosmos DB account name'
  }
  default: 'cosmos-${uniqueString(resourceGroup().id)}'
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
    description: 'The name for the Core (SQL) database'
  }
}
param containerName string {
  metadata: {
    description: 'The name for the Core (SQL) API container'
  }
  default: 'container1'
}
param throughput int {
  minValue: 400
  maxValue: 1000000
  metadata: {
    description: 'The throughput for the container'
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
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-03-01' = {
  name: '${accountName_var}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
  dependsOn: [
    accountName_res
  ]
}

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${containerName}'
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
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
    }
    options: {
      throughput: throughput
    }
  }
  dependsOn: [
    accountName_databaseName
  ]
}

resource accountName_databaseName_containerName_myStoredProcedure 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/storedProcedures@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${containerName}/myStoredProcedure'
  properties: {
    resource: {
      id: 'myStoredProcedure'
      body: 'function () { var context = getContext(); var response = context.getResponse(); response.setBody(\'Hello, World\'); }'
    }
  }
  dependsOn: [
    accountName_databaseName_containerName
  ]
}

resource accountName_databaseName_containerName_myPreTrigger 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/triggers@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${containerName}/myPreTrigger'
  properties: {
    resource: {
      id: 'myPreTrigger'
      triggerType: 'Pre'
      triggerOperation: 'Create'
      body: 'function validateToDoItemTimestamp(){var context=getContext();var request=context.getRequest();var itemToCreate=request.getBody();if(!(\'timestamp\'in itemToCreate)){var ts=new Date();itemToCreate[\'timestamp\']=ts.getTime();}request.setBody(itemToCreate);}'
    }
  }
  dependsOn: [
    accountName_databaseName_containerName
  ]
}

resource accountName_databaseName_containerName_myUserDefinedFunction 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/userDefinedFunctions@2020-03-01' = {
  name: '${accountName_var}/${databaseName}/${containerName}/myUserDefinedFunction'
  properties: {
    resource: {
      id: 'myUserDefinedFunction'
      body: 'function tax(income){if(income==undefined)throw\'no input\';if(income<1000)return income*0.1;else if(income<10000)return income*0.2;else return income*0.4;}'
    }
  }
  dependsOn: [
    accountName_databaseName_containerName
  ]
}
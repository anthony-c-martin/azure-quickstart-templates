param accountName string {
  metadata: {
    description: 'Cosmos DB account name'
  }
  default: 'cosmos${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for the Cosmos DB account.'
  }
  default: resourceGroup().location
}
param databaseName string {
  metadata: {
    description: 'The name for the database'
  }
  default: 'database1'
}
param containerName string {
  metadata: {
    description: 'The name for the container'
  }
  default: 'container1'
}
param partitionKeyPath string {
  metadata: {
    description: 'The partition key for the container'
  }
  default: '/partitionKey'
}
param throughputPolicy string {
  allowed: [
    'Manual'
    'Autoscale'
  ]
  metadata: {
    description: 'The throughput policy for the container'
  }
  default: 'Autoscale'
}
param manualProvisionedThroughput int {
  minValue: 400
  maxValue: 1000000
  metadata: {
    description: 'Throughput value when using Manual Throughput Policy for the container'
  }
  default: 400
}
param autoscaleMaxThroughput int {
  minValue: 4000
  maxValue: 1000000
  metadata: {
    description: 'Maximum throughput when using Autoscale Throughput Policy for the container'
  }
  default: 4000
}

var accountName_var = toLower(accountName)
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]
var throughputPolicy_var = {
  Manual: {
    Throughput: manualProvisionedThroughput
  }
  Autoscale: {
    autoscaleSettings: {
      maxThroughput: autoscaleMaxThroughput
    }
  }
}

resource accountName_res 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: accountName_var
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    locations: locations
    enableAnalyticalStorage: true
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-04-01' = {
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

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-04-01' = {
  name: '${accountName_var}/${databaseName}/${containerName}'
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          partitionKeyPath
        ]
        kind: 'Hash'
      }
      analyticalStorageTtl: -1
    }
    options: throughputPolicy_var[throughputPolicy]
  }
  dependsOn: [
    accountName_databaseName
  ]
}
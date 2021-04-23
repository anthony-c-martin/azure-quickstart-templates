@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('Cosmos Account Name')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'

@description('Database name')
param databaseName string = 'myDatabase'

@description('Array of Container Object with name and partition key')
param containers array

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2019-12-12' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
      maxStalenessPrefix: 1
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource accountName_sql_databaseName 'Microsoft.DocumentDB/databaseAccounts/apis/databases@2016-03-31' = {
  name: '${accountName}/sql/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 400
    }
  }
  dependsOn: [
    accountName_resource
  ]
}

resource accountName_sql_databaseName_containers_name 'Microsoft.DocumentDb/databaseAccounts/apis/databases/containers@2016-03-31' = [for item in containers: {
  name: '${accountName}/sql/${databaseName}/${item.name}'
  properties: {
    resource: {
      id: item.name
      partitionKey: {
        paths: [
          item.partitionKey
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'Consistent'
      }
    }
  }
  dependsOn: [
    accountName_sql_databaseName
  ]
}]
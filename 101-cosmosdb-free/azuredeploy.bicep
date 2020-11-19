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
param databaseName string {
  metadata: {
    description: 'The name for the Core (SQL) database'
  }
}

var accountName_var = toLower(accountName)

resource accountName_res 'Microsoft.DocumentDB/databaseAccounts@2020-03-01' = {
  name: accountName
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-03-01' = {
  name: '${accountName_var}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 400
    }
  }
}
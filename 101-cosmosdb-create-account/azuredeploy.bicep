param name string {
  metadata: {
    description: 'The name of your CosmosDB account'
  }
  default: uniqueString('cosmosdb', resourceGroup().id)
}
param location string {
  metadata: {
    description: 'Location for your CosmosDB account'
  }
  default: resourceGroup().location
}
param tier string {
  metadata: {
    description: 'CosmosDB account tier'
  }
  default: 'Standard'
}

resource name_res 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: name
  location: location
  properties: {
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: tier
  }
}
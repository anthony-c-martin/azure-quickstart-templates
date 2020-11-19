param databaseAccountName string {
  metadata: {
    description: 'The Azure Cosmos DB database account name.'
  }
}
param appSvcPlanName string {
  metadata: {
    description: 'The name of the App Service Plan that will host the Web App.'
  }
}
param svcPlanSize string {
  metadata: {
    description: 'The instance size of the App Service Plan.'
  }
  default: 'F1'
}
param svcPlanSku string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier of the App Service plan.'
  }
  default: 'Free'
}
param webAppName string {
  metadata: {
    description: 'The name of the Web App.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var databaseAccountTier = 'Standard'

resource databaseAccountName_resource 'Microsoft.DocumentDb/databaseAccounts@2015-04-08' = {
  name: databaseAccountName
  location: location
  properties: {
    name: databaseAccountName
    databaseAccountOfferType: databaseAccountTier
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

resource appSvcPlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: appSvcPlanName
  location: location
  sku: {
    name: svcPlanSize
    tier: svcPlanSku
    capacity: 1
  }
}

resource webAppName_resource 'Microsoft.Web/Sites@2015-08-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    serverFarmId: appSvcPlanName
    siteConfig: {
      phpVersion: 'off'
      appSettings: [
        {
          Name: 'DOCUMENTDB_ENDPOINT'
          Value: reference('Microsoft.DocumentDb/databaseAccounts/${databaseAccountName}').documentEndpoint
        }
        {
          Name: 'DOCUMENTDB_PRIMARY_KEY'
          Value: listKeys(databaseAccountName_resource.id, '2015-04-08').primaryMasterKey
        }
      ]
    }
  }
  dependsOn: [
    appSvcPlanName_resource
  ]
}
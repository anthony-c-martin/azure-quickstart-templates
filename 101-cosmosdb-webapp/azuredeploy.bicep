param applicationName string {
  metadata: {
    description: 'Application Name, max length 30 characters'
  }
  default: 'to-do-app${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param appServicePlanTier string {
  allowed: [
    'F1'
    'D1'
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P4'
  ]
  metadata: {
    description: 'App Service Plan\'s pricing tier. Details at https://azure.microsoft.com/en-us/pricing/details/app-service/'
  }
  default: 'F1'
}
param appServicePlanInstances int {
  minValue: 1
  maxValue: 3
  metadata: {
    description: 'App Service Plan\'s instance count'
  }
  default: 1
}
param repositoryURL string {
  metadata: {
    description: 'The URL for the GitHub repository that contains the project to deploy.'
  }
  default: 'https://github.com/Azure-Samples/cosmos-dotnet-core-todo-app.git'
}
param branch string {
  metadata: {
    description: 'The branch of the GitHub repository to use.'
  }
  default: 'master'
}
param databaseName string {
  metadata: {
    description: 'The Cosmos DB database name.'
  }
  default: 'Tasks'
}
param containerName string {
  metadata: {
    description: 'The Cosmos DB container name.'
  }
  default: 'Items'
}

var cosmosAccountName_var = toLower(applicationName)
var webSiteName_var = applicationName
var hostingPlanName_var = applicationName

resource cosmosAccountName 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: cosmosAccountName_var
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: appServicePlanTier
    capacity: appServicePlanInstances
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2019-08-01' = {
  name: webSiteName_var
  location: location
  properties: {
    serverFarmId: hostingPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'CosmosDb:Account'
          value: cosmosAccountName.properties.documentEndpoint
        }
        {
          name: 'CosmosDb:Key'
          value: listKeys(cosmosAccountName.id, '2020-04-01').primaryMasterKey
        }
        {
          name: 'CosmosDb:DatabaseName'
          value: databaseName
        }
        {
          name: 'CosmosDb:ContainerName'
          value: containerName
        }
      ]
    }
  }
}

resource webSiteName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${webSiteName_var}/web'
  location: location
  properties: {
    repoUrl: repositoryURL
    branch: branch
    isManualIntegration: true
  }
}
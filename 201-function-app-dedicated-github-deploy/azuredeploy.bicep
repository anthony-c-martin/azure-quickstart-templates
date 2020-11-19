param appName string {
  metadata: {
    description: 'The name of the function app that you wish to create.'
  }
  default: 'funtionapp-${uniqueString(resourceGroup().id)}'
}
param sku string {
  metadata: {
    description: 'The pricing tier for the hosting plan.'
  }
  default: 'S1'
}
param workerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'The instance size of the hosting plan (small, medium, or large).'
  }
  default: '0'
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param repoURL string {
  metadata: {
    description: 'The URL for the GitHub repository that contains the project to deploy.'
  }
  default: 'https://github.com/AzureBytes/functionshttpecho.git'
}
param branch string {
  metadata: {
    description: 'The branch of the GitHub repository to use.'
  }
  default: 'master'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var functionAppName = appName
var hostingPlanName = '${appName}-plan'
var storageAccountName = '${uniqueString(resourceGroup().id)}functions'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-11-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: sku
  }
  properties: {
    workerSize: workerSize
    numberOfWorkers: 1
  }
}

resource functionAppName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    name: functionAppName
    serverFarmId: hostingPlanName_resource.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listkeys(storageAccountName_resource.id, '2018-11-01').keys[0].value};'
        }
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listkeys(storageAccountName_resource.id, '2018-11-01').keys[0].value};'
        }
      ]
    }
  }
  dependsOn: [
    hostingPlanName_resource
    storageAccountName_resource
  ]
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2018-11-01' = {
  name: '${functionAppName}/web'
  properties: {
    RepoUrl: repoURL
    branch: branch
    IsManualIntegration: true
  }
  dependsOn: [
    functionAppName_resource
  ]
}
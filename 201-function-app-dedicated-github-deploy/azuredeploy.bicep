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

var functionAppName_var = appName
var hostingPlanName_var = '${appName}-plan'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}functions'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2018-11-01' = {
  name: storageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: sku
  }
  properties: {
    workerSize: workerSize
    numberOfWorkers: 1
  }
}

resource functionAppName 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    name: functionAppName_var
    serverFarmId: hostingPlanName.id
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listkeys(storageAccountName.id, '2018-11-01').keys[0].value};'
        }
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listkeys(storageAccountName.id, '2018-11-01').keys[0].value};'
        }
      ]
    }
  }
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2018-11-01' = {
  name: '${functionAppName_var}/web'
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
  dependsOn: [
    functionAppName
  ]
}
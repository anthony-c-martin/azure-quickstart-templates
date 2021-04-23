@description('The name of the function app that you wish to create.')
param appName string = 'funtionapp-${uniqueString(resourceGroup().id)}'

@description('The pricing tier for the hosting plan.')
param sku string = 'S1'

@allowed([
  '0'
  '1'
  '2'
])
@description('The instance size of the hosting plan (small, medium, or large).')
param workerSize string = '0'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string = 'https://github.com/AzureBytes/functionshttpecho.git'

@description('The branch of the GitHub repository to use.')
param branch string = 'master'

@description('Location for all resources.')
param location string = resourceGroup().location

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
  parent: functionAppName
  name: 'web'
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
}
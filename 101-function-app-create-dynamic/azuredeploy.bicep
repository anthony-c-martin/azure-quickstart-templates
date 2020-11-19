param appName string {
  metadata: {
    description: 'The name of the function app that you wish to create.'
  }
  default: 'fnapp${uniqueString(resourceGroup().id)}'
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param appInsightsLocation string {
  metadata: {
    description: 'Location for Application Insights'
  }
}
param runtime string {
  allowed: [
    'node'
    'dotnet'
    'java'
  ]
  metadata: {
    description: 'The language worker runtime to load in the function app.'
  }
  default: 'node'
}

var functionAppName_var = appName
var hostingPlanName_var = appName
var applicationInsightsName_var = appName
var storageAccountName_var = '${uniqueString(resourceGroup().id)}azfunctions'
var functionWorkerRuntime = runtime

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    name: hostingPlanName_var
    computeMode: 'Dynamic'
  }
}

resource functionAppName 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName_var)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(applicationInsightsName.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
    }
  }
}

resource applicationInsightsName 'microsoft.insights/components@2020-02-02-preview' = {
  name: applicationInsightsName_var
  location: appInsightsLocation
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', applicationInsightsName_var)}': 'Resource'
  }
  properties: {
    ApplicationId: applicationInsightsName_var
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}
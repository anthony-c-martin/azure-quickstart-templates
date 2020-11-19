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

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var functionWorkerRuntime = runtime

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    name: hostingPlanName
    computeMode: 'Dynamic'
  }
}

resource functionAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName_resource.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
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
          value: reference(applicationInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
    }
  }
  dependsOn: [
    hostingPlanName_resource
    storageAccountName_resource
  ]
}

resource applicationInsightsName_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: appInsightsLocation
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', applicationInsightsName)}': 'Resource'
  }
  properties: {
    ApplicationId: applicationInsightsName
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}
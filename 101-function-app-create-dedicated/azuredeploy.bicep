param appName string {
  metadata: {
    description: 'The name of the function app that you wish to create.'
  }
}
param sku string {
  allowed: [
    'D1'
    'F1'
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P1V2'
    'P2V2'
    'P3V2'
    'I1'
    'I2'
    'I3'
    'Y1'
  ]
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

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}functions'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
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

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    Name: sku
  }
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    numberOfWorkers: 1
  }
}

resource functionAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    name: functionAppName
    serverFarmId: hostingPlanName_resource.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
    }
  }
  dependsOn: [
    hostingPlanName_resource
    storageAccountName_resource
  ]
}

resource functionAppName_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: '${functionAppName}/appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: reference(applicationInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
  }
  dependsOn: [
    functionAppName_resource
    storageAccountName_resource
  ]
}
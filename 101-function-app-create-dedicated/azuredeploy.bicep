@description('The name of the function app that you wish to create.')
param appName string

@allowed([
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
])
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
  'Standard_RAGRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Location for Application Insights')
param appInsightsLocation string

var functionAppName_var = appName
var hostingPlanName_var = appName
var applicationInsightsName_var = appName
var storageAccountName_var = '${uniqueString(resourceGroup().id)}functions'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
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

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: sku
  }
  properties: {
    name: hostingPlanName_var
    workerSize: workerSize
    numberOfWorkers: 1
  }
}

resource functionAppName 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    name: functionAppName_var
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource functionAppName_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: functionAppName
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: reference(applicationInsightsName.id, '2020-02-02-preview').InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
  }
}
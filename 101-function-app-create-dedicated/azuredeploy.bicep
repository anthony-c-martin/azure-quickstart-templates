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
}

resource functionAppName_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: '${functionAppName_var}/appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: reference(applicationInsightsName.id, '2020-02-02-preview').InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
  }
}
@description('The name of Storage Account.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('The name of Blob Container to store diagnostics logs from Web App.')
param blobContainerName string = '${webAppName}-logs'

@description('The name of the App Service Plan.')
param storageAccountSkuName string = 'Standard_LRS'

@description('The name of the Storage Account Type.')
param storageAccountKind string = 'StorageV2'

@description('The name of the App Service Plan.')
param appServicePlanName string = 'appServicePlan-${uniqueString(resourceGroup().id)}'

@description('The SKU name of the App Serivce Plan.')
param appServicePlanSkuName string = 'F1'

@description('The name of the Web App.')
param webAppName string = 'webApp-${uniqueString(resourceGroup().id)}'

@allowed([
  'Verbose'
  'Information'
  'Warning'
  'Error'
])
@description('The degree of severity for diagnostics logs.')
param diagnosticsLogsLevel string = 'Verbose'

@description('Number of days for which the diagnostics logs will be retained.')
param diagnosticsLogsRetentionInDays int = 10

@description('Location for all resources.')
param location string = resourceGroup().location

var blobContainerName_var = toLower(blobContainerName)
var listAccountSasRequestContent = {
  signedServices: 'bfqt'
  signedPermission: 'rwdlacup'
  signedStart: '10/1/2018 12:00:00 AM'
  signedExpiry: '10/30/2218 12:00:00 AM'
  signedResourceTypes: 'sco'
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: storageAccountKind
}

resource storageAccountName_default_blobContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-02-01' = {
  name: '${storageAccountName}/default/${blobContainerName_var}'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2018-02-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    serverFarmId: '/subscriptions/${subscription().id}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName}'
  }
  dependsOn: [
    appServicePlanName_resource
    storageAccountName_resource
  ]
}

resource webAppName_logs 'Microsoft.Web/sites/config@2018-02-01' = {
  parent: webAppName_resource
  name: 'logs'
  properties: {
    applicationLogs: {
      azureBlobStorage: {
        level: diagnosticsLogsLevel
        sasUrl: '${reference('Microsoft.Storage/storageAccounts/${storageAccountName}').primaryEndpoints.blob}${blobContainerName_var}?${listAccountSas(storageAccountName, '2018-02-01', listAccountSasRequestContent).accountSasToken}'
        retentionInDays: diagnosticsLogsRetentionInDays
      }
    }
  }
}
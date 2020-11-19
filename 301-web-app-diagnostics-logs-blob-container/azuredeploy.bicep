param storageAccountName string {
  metadata: {
    description: 'The name of Storage Account.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param blobContainerName string {
  metadata: {
    description: 'The name of Blob Container to store diagnostics logs from Web App.'
  }
  default: '${webAppName}-logs'
}
param storageAccountSkuName string {
  metadata: {
    description: 'The name of the App Service Plan.'
  }
  default: 'Standard_LRS'
}
param storageAccountKind string {
  metadata: {
    description: 'The name of the Storage Account Type.'
  }
  default: 'StorageV2'
}
param appServicePlanName string {
  metadata: {
    description: 'The name of the App Service Plan.'
  }
  default: 'appServicePlan-${uniqueString(resourceGroup().id)}'
}
param appServicePlanSkuName string {
  metadata: {
    description: 'The SKU name of the App Serivce Plan.'
  }
  default: 'F1'
}
param webAppName string {
  metadata: {
    description: 'The name of the Web App.'
  }
  default: 'webApp-${uniqueString(resourceGroup().id)}'
}
param diagnosticsLogsLevel string {
  allowed: [
    'Verbose'
    'Information'
    'Warning'
    'Error'
  ]
  metadata: {
    description: 'The degree of severity for diagnostics logs.'
  }
  default: 'Verbose'
}
param diagnosticsLogsRetentionInDays int {
  metadata: {
    description: 'Number of days for which the diagnostics logs will be retained.'
  }
  default: 10
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var blobContainerName_var = toLower(blobContainerName)
var listAccountSasRequestContent = {
  signedServices: 'bfqt'
  signedPermission: 'rwdlacup'
  signedStart: '10/1/2018 12:00:00 AM'
  signedExpiry: '10/30/2218 12:00:00 AM'
  signedResourceTypes: 'sco'
}

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2018-02-01' = {
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
}

resource appServicePlanName_res 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource webAppName_res 'Microsoft.Web/sites@2018-02-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    serverFarmId: '/subscriptions/${subscription().id}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName}'
  }
}

resource webAppName_logs 'Microsoft.Web/sites/config@2018-02-01' = {
  name: '${webAppName}/logs'
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
@description('Specifies the name of the Azure Storage account.')
param storageAccountName string

@description('Specifies the prefix of the blob container names.')
param containerPrefix string = 'logs'

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string = resourceGroup().location

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource storageAccountName_default_containerPrefix 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for i in range(0, 3): {
  name: '${storageAccountName}/default/${containerPrefix}${i}'
  dependsOn: [
    storageAccountName_resource
  ]
}]
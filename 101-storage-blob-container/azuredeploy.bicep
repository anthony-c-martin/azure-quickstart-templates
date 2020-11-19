param storageAccountName string {
  metadata: {
    description: 'Specifies the name of the Azure Storage account.'
  }
}
param containerName string {
  metadata: {
    description: 'Specifies the name of the blob container.'
  }
  default: 'logs'
}
param location string {
  metadata: {
    description: 'Specifies the location in which the Azure Storage resources should be deployed.'
  }
  default: resourceGroup().location
}

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName}/default/${containerName}'
}
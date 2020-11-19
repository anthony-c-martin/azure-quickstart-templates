param batchAccountName string {
  metadata: {
    description: 'Batch Account Name'
  }
  default: '${toLower(uniqueString(resourceGroup().id))}batch'
}
param storageAccountsku string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
    'Premium_LRS'
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

var storageAccountName_variable = '${uniqueString(resourceGroup().id)}storage'

resource storageAccountname_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_variable
  location: location
  sku: {
    name: storageAccountsku
  }
  kind: 'StorageV2'
  tags: {
    ObjectName: storageAccountName_variable
  }
  properties: {}
}

resource batchAccountName_resource 'Microsoft.Batch/batchAccounts@2020-05-01' = {
  name: batchAccountName
  location: location
  tags: {
    ObjectName: batchAccountName
  }
  properties: {
    autoStorage: {
      storageAccountId: storageAccountname_resource.id
    }
  }
  dependsOn: [
    storageAccountname_resource
  ]
}

output storageAccountName string = storageAccountName_variable
output batchAccountName_output string = batchAccountName
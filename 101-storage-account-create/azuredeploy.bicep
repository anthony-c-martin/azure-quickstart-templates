param storageAccountType string {
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

var storageAccountName_variable = 'store${uniqueString(resourceGroup().id)}'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_variable
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

output storageAccountName string = storageAccountName_variable
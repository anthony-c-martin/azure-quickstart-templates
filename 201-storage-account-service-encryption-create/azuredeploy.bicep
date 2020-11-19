param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Storage Account type.'
  }
  default: 'Standard_LRS'
}
param blobEncryptionEnabled bool {
  metadata: {
    description: 'Enable or disable Blob encryption at Rest.'
  }
  default: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName_variable = toLower('sawithsse${substring(storageAccountType, 0, 2)}${uniqueString(subscription().id, resourceGroup().id)}')

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-12-01' = {
  name: storageAccountName_variable
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: blobEncryptionEnabled
        }
      }
    }
  }
}

output storageAccountName string = storageAccountName_variable
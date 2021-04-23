@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage Account type.')
param storageAccountType string = 'Standard_LRS'

@description('Enable or disable Blob encryption at Rest.')
param blobEncryptionEnabled bool = true

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = toLower('sawithsse${substring(storageAccountType, 0, 2)}${uniqueString(subscription().id, resourceGroup().id)}')

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-12-01' = {
  name: storageAccountName_var
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

output storageAccountName string = storageAccountName_var
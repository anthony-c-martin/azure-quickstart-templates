param storageAccountName string {
  metadata: {
    description: 'Specifies the name of the Azure Storage account.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param fileShareName string {
  minLength: 3
  maxLength: 63
  metadata: {
    description: 'Specifies the name of the File Share. File share names must be between 3 and 63 characters in length and use numbers, lower-case letters and dash (-) only.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the location in which the Azure Storage resources should be deployed.'
  }
  default: resourceGroup().location
}

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

resource storageAccountName_default_fileShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
  dependsOn: [
    storageAccountName_resource
  ]
}
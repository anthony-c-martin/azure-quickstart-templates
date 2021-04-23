@description('Name of the Media Services account. A Media Services account name is globally unique, all lowercase letters or numbers with no spaces.')
param mediaServiceName string

@description('Location for all resources.')
param location string = resourceGroup().location

var storageName_var = 'storage${uniqueString(resourceGroup().id)}'

resource storageName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource mediaServiceName_resource 'Microsoft.Media/mediaServices@2020-05-01' = {
  name: mediaServiceName
  location: location
  properties: {
    storageAccounts: [
      {
        id: storageName.id
        type: 'Primary'
      }
    ]
  }
}
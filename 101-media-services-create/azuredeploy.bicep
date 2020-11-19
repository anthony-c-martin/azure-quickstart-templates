param mediaServiceName string {
  metadata: {
    description: 'Name of the Media Services account. A Media Services account name is globally unique, all lowercase letters or numbers with no spaces.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageName = 'storage${uniqueString(resourceGroup().id)}'

resource mediaServiceName_resource 'Microsoft.Media/mediaServices@2018-07-01' = {
  name: mediaServiceName
  location: location
  properties: {
    storageAccounts: [
      {
        id: storageName_resource.id
        type: 'Primary'
      }
    ]
  }
  dependsOn: [
    storageName_resource
  ]
}

resource storageName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
}
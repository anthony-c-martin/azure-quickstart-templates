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

var storageName_var = 'storage${uniqueString(resourceGroup().id)}'

resource mediaServiceName_res 'Microsoft.Media/mediaServices@2018-07-01' = {
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

resource storageName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName_var
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
}
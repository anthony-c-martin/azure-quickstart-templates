param storageName string {
  metadata: {
    description: 'Provide a unique name for the Blob Storage account.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Provide a location for the Blob Storage account that supports Event Grid.'
  }
  default: resourceGroup().location
}
param eventSubName string {
  metadata: {
    description: 'Provide a name for the Event Grid subscription.'
  }
  default: 'subToStorage'
}
param endpoint string {
  metadata: {
    description: 'Provide the URL for the WebHook to receive events. Create your own endpoint for events.'
  }
}
param systemTopicName string {
  metadata: {
    description: 'Provide a name for the system topic.'
  }
  default: 'mystoragesystemtopic'
}

resource storageName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource systemTopicName_res 'Microsoft.EventGrid/systemTopics@2020-04-01-preview' = {
  name: systemTopicName
  location: location
  properties: {
    source: storageName_res.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource systemTopicName_eventSubName 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-04-01-preview' = {
  name: '${systemTopicName}/${eventSubName}'
  properties: {
    destination: {
      properties: {
        endpointUrl: endpoint
      }
      endpointType: 'WebHook'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
        'Microsoft.Storage.BlobDeleted'
      ]
    }
  }
}
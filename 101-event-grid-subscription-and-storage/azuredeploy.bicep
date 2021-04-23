@description('Provide a unique name for the Blob Storage account.')
param storageName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Provide a location for the Blob Storage account that supports Event Grid.')
param location string = resourceGroup().location

@description('Provide a name for the Event Grid subscription.')
param eventSubName string = 'subToStorage'

@description('Provide the URL for the WebHook to receive events. Create your own endpoint for events.')
param endpoint string

@description('Provide a name for the system topic.')
param systemTopicName string = 'mystoragesystemtopic'

resource storageName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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

resource systemTopicName_resource 'Microsoft.EventGrid/systemTopics@2020-04-01-preview' = {
  name: systemTopicName
  location: location
  properties: {
    source: storageName_resource.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource systemTopicName_eventSubName 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-04-01-preview' = {
  parent: systemTopicName_resource
  name: '${eventSubName}'
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
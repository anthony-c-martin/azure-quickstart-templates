@description('The name of the Event Grid custom topic.')
param topicName string = 'topic${uniqueString(resourceGroup().id)}'

@description('The name of the Event Grid custom topic\'s subscription.')
param subscriptionName string = 'subSendToEventHubs'

@description('The name of the Event Hubs namespace.')
param eventHubNamespace string = 'namespace${uniqueString(resourceGroup().id)}'

@description('The name of the event hub.')
param eventHubName string = 'eventhub'

@description('The location in which the Event Grid resources should be deployed.')
param location string = resourceGroup().location

resource topicName_resource 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: topicName
  location: location
}

resource eventHubNamespace_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventHubNamespace
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 7
  }
}

resource eventHubNamespace_eventHubName 'Microsoft.EventHub/namespaces/EventHubs@2017-04-01' = {
  parent: eventHubNamespace_resource
  name: '${eventHubName}'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

resource subscriptionName_resource 'Microsoft.EventGrid/eventSubscriptions@2020-06-01' = {
  name: subscriptionName
  properties: {
    destination: {
      endpointType: 'EventHub'
      properties: {
        resourceId: eventHubNamespace_eventHubName.id
      }
    }
    filter: {
      isSubjectCaseSensitive: false
    }
  }
  scope: topicName_resource
  dependsOn: [
    topicName_resource
  ]
}

output endpoint string = reference(topicName).endpoint
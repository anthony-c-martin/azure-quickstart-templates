param topicName string {
  metadata: {
    description: 'The name of the Event Grid custom topic.'
  }
  default: 'topic${uniqueString(resourceGroup().id)}'
}
param subscriptionName string {
  metadata: {
    description: 'The name of the Event Grid custom topic\'s subscription.'
  }
  default: 'subSendToEventHubs'
}
param eventHubNamespace string {
  metadata: {
    description: 'The name of the Event Hubs namespace.'
  }
  default: 'namespace${uniqueString(resourceGroup().id)}'
}
param eventHubName string {
  metadata: {
    description: 'The name of the event hub.'
  }
  default: 'eventhub'
}
param location string {
  metadata: {
    description: 'The location in which the Event Grid resources should be deployed.'
  }
  default: resourceGroup().location
}

resource topicName_resource 'Microsoft.EventGrid/topics@2018-01-01' = {
  name: topicName
  location: location
}

resource eventHubNamespace_resource 'Microsoft.EventHub/namespaces@2017-04-01' = {
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
  name: '${eventHubNamespace}/${eventHubName}'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
  dependsOn: [
    eventHubNamespace_resource
  ]
}

resource topicName_Microsoft_EventGrid_subscriptionName 'Microsoft.EventGrid/topics/providers/eventSubscriptions@2018-01-01' = {
  name: '${topicName}/Microsoft.EventGrid/${subscriptionName}'
  properties: {
    destination: {
      endpointType: 'EventHub'
      properties: {
        resourceId: eventHubNamespace_eventHubName.id
      }
    }
    filter: {
      subjectBeginsWith: ''
      subjectEndsWith: ''
      isSubjectCaseSensitive: false
      includedEventTypes: [
        'All'
      ]
    }
  }
  dependsOn: [
    topicName_resource
    eventHubNamespace_eventHubName
  ]
}

output endpoint string = reference(topicName).endpoint
output key string = listKeys(topicName, '2018-01-01').key1
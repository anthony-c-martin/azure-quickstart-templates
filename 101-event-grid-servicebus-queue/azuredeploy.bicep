param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
  }
}
param serviceBusQueueName string {
  metadata: {
    description: 'Name of the Queue'
  }
}
param eventGridTopicName string {
  metadata: {
    description: 'The name of the Event Grid custom topic.'
  }
}
param eventGridSubscriptionName string {
  metadata: {
    description: 'The name of the Event Grid custom topic\'s subscription.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the Event Grid resources should be deployed.'
  }
  default: resourceGroup().location
}

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusNamespaceName_serviceBusQueueName 'Microsoft.ServiceBus/namespaces/Queues@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusQueueName}'
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: '1024'
    requiresDuplicateDetection: 'false'
    requiresSession: 'false'
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: 'false'
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: '10'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: 'false'
    enableExpress: 'false'
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

resource eventGridTopicName_resource 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: eventGridTopicName
  location: location
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

resource eventGridTopicName_Microsoft_EventGrid_eventGridSubscriptionName 'Microsoft.EventGrid/topics/providers/eventSubscriptions@2020-01-01-preview' = {
  name: '${eventGridTopicName}/Microsoft.EventGrid/${eventGridSubscriptionName}'
  location: location
  properties: {
    destination: {
      endpointType: 'ServiceBusQueue'
      properties: {
        resourceId: serviceBusNamespaceName_serviceBusQueueName.id
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      isSubjectCaseSensitive: false
    }
  }
  dependsOn: [
    eventGridTopicName_resource
  ]
}
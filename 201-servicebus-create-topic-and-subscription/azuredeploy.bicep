@description('Name of the Service Bus namespace')
param service_BusNamespace_Name string

@description('Name of the Topic')
param serviceBusTopicName string

@description('Name of the Subscription')
param serviceBusSubscriptionName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource service_BusNamespace_Name_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: service_BusNamespace_Name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource service_BusNamespace_Name_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: service_BusNamespace_Name_resource
  name: '${serviceBusTopicName}'
  properties: {
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: false
    supportOrdering: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource service_BusNamespace_Name_serviceBusTopicName_serviceBusSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  parent: service_BusNamespace_Name_serviceBusTopicName
  name: serviceBusSubscriptionName
  properties: {
    lockDuration: 'PT1M'
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    maxDeliveryCount: 10
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
}
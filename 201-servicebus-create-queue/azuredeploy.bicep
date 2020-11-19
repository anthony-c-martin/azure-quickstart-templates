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
param location string {
  metadata: {
    description: 'Location for all resources.'
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
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}
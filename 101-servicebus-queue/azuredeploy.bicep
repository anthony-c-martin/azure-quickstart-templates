@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Queue')
param serviceBusQueueName1 string

@description('Name of the Queue')
param serviceBusQueueName2 string

@description('Location for all resources.')
param location string = resourceGroup().location

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, defaultSASKeyName)

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusNamespaceName_serviceBusQueueName1 'Microsoft.ServiceBus/namespaces/Queues@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusQueueName1}'
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
}

resource serviceBusNamespaceName_serviceBusQueueName2 'Microsoft.ServiceBus/namespaces/Queues@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusQueueName2}'
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
    forwardTo: serviceBusQueueName1
    forwardDeadLetteredMessagesTo: serviceBusQueueName1
  }
  dependsOn: [
    serviceBusNamespaceName_serviceBusQueueName1
  ]
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey
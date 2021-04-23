@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Namespace AuthorizationRule')
param namespaceAuthorizationRuleName string

@description('Name of the Queue')
param serviceBusQueueName string

@description('Name of the Queue AuthorizationRule')
param queueAuthorizationRuleName string

@description('Location for all resources.')
param location string = resourceGroup().location

var namespaceAuthRuleName_var = '${serviceBusNamespaceName}/${namespaceAuthorizationRuleName}'
var nsAuthorizationRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, namespaceAuthorizationRuleName)
var ehAuthorizationRuleResourceId = serviceBusNamespaceName_serviceBusQueueName_queueAuthorizationRuleName.id
var sbVersion = '2017-04-01'

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource serviceBusNamespaceName_serviceBusQueueName 'Microsoft.ServiceBus/namespaces/Queues@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusQueueName}'
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

resource serviceBusNamespaceName_serviceBusQueueName_queueAuthorizationRuleName 'Microsoft.ServiceBus/namespaces/Queues/AuthorizationRules@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusQueueName
  name: queueAuthorizationRuleName
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource namespaceAuthRuleName 'Microsoft.ServiceBus/namespaces/authorizationRules@2017-04-01' = {
  name: namespaceAuthRuleName_var
  location: location
  properties: {
    rights: [
      'Send'
    ]
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

output NamespaceConnectionString string = listkeys(nsAuthorizationRuleResourceId, sbVersion).primaryConnectionString
output NamespaceSharedAccessPolicyPrimaryKey string = listkeys(nsAuthorizationRuleResourceId, sbVersion).primaryKey
output EventHubConnectionString string = listkeys(ehAuthorizationRuleResourceId, sbVersion).primaryConnectionString
output EventHubSharedAccessPolicyPrimaryKey string = listkeys(ehAuthorizationRuleResourceId, sbVersion).primaryKey
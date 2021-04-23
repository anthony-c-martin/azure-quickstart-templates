@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Topic')
param serviceBusTopicName string

@description('Name of the Subscription')
param serviceBusSubscriptionName string

@description('Name of the Rule')
param serviceBusRuleName string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, defaultSASKeyName)
var sbVersion = '2017-04-01'

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName}'
  properties: {
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    maxSizeInMegabytes: '1024'
    requiresDuplicateDetection: 'false'
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: 'false'
    supportOrdering: 'false'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: 'false'
    enableExpress: 'false'
  }
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusTopicName
  name: serviceBusSubscriptionName
  properties: {
    lockDuration: 'PT1M'
    requiresSession: 'false'
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: 'false'
    maxDeliveryCount: '10'
    enableBatchedOperations: 'false'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName_serviceBusRuleName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions/Rules@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName
  name: serviceBusRuleName
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'FilterTag = \'true\''
      requiresPreprocessing: 'false'
    }
  }
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, sbVersion).primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, sbVersion).primaryKey
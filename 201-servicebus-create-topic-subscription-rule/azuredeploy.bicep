param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
  }
}
param serviceBusTopicName string {
  metadata: {
    description: 'Name of the Topic'
  }
}
param serviceBusSubscriptionName string {
  metadata: {
    description: 'Name of the Subscription'
  }
}
param serviceBusRuleName string {
  metadata: {
    description: 'Name of the Rule'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var location_variable = location
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
  name: '${serviceBusNamespaceName}/${serviceBusTopicName}'
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
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName}/${serviceBusSubscriptionName}'
  properties: {
    lockDuration: 'PT1M'
    requiresSession: 'false'
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: 'false'
    maxDeliveryCount: '10'
    enableBatchedOperations: 'false'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
  dependsOn: [
    serviceBusNamespaceName_serviceBusTopicName
  ]
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName_serviceBusRuleName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions/Rules@2017-04-01' = {
  name: '${'${serviceBusNamespaceName}/${serviceBusTopicName}'}/${serviceBusSubscriptionName}/${serviceBusRuleName}'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'FilterTag = \'true\''
      requiresPreprocessing: 'false'
    }
  }
  dependsOn: [
    serviceBusNamespaceName_serviceBusTopicName_serviceBusSubscriptionName
  ]
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, sbVersion).primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, sbVersion).primaryKey
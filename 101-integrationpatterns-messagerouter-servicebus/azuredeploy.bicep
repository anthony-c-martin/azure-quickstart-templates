@description('The name for the Service Bus Topic.')
param IncomingDeliveryRequestsTopicname string = 'incomingdeliveryrequests'

@description('The prefix of the name for the Service Bus namespace, will be appended with a unique string.')
param MessageRouterServiceBusnamespacePrefix string = 'MessageRouterServiceBus'

@description('Location for all resources.')
param location string = resourceGroup().location

var serviceBusnamespacename_var = '${MessageRouterServiceBusnamespacePrefix}-${uniqueString(resourceGroup().id)}'

resource serviceBusnamespacename 'Microsoft.ServiceBus/namespaces@2015-08-01' = {
  name: serviceBusnamespacename_var
  location: location
  kind: 'Messaging'
  sku: {
    name: 'Standard'
    capacity: 1
    tier: 'Standard'
  }
  dependsOn: []
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname 'Microsoft.ServiceBus/namespaces/topics@2015-08-01' = {
  parent: serviceBusnamespacename
  name: '${IncomingDeliveryRequestsTopicname}'
  location: location
  properties: {
    defaultMessageTimeToLive: '14.00:00:00'
    enableBatchedOperations: false
    enableExpress: false
    enablePartitioning: true
    enableSubscriptionPartitioning: false
    filteringMessagesBeforePublishing: false
    isAnonymousAccessible: false
    isExpress: false
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    sizeInBytes: 0
    supportOrdering: false
  }
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  name: 'HighPriority'
  location: location
  properties: {
    deadLetteringOnFilterEvaluationExceptions: false
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: '14.00:00:00'
    enableBatchedOperations: false
    lockDuration: '00:00:30'
    maxDeliveryCount: 10
    requiresSession: false
  }
  dependsOn: [
    serviceBusnamespacename
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority_HighPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority
  name: 'HighPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'High\''
    }
  }
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  name: 'Log'
  location: location
  properties: {
    deadLetteringOnFilterEvaluationExceptions: false
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: '14.00:00:00'
    enableBatchedOperations: false
    lockDuration: '00:00:30'
    maxDeliveryCount: 10
    requiresSession: false
  }
  dependsOn: [
    serviceBusnamespacename
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log_LogAll 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log
  name: 'LogAll'
  properties: {
    filter: {
      sqlExpression: '1=1'
    }
  }
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  name: 'LowPriority'
  location: location
  properties: {
    deadLetteringOnFilterEvaluationExceptions: false
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: '14.00:00:00'
    enableBatchedOperations: false
    lockDuration: '00:00:30'
    maxDeliveryCount: 10
    requiresSession: false
  }
  dependsOn: [
    serviceBusnamespacename
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority_LowPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority
  name: 'LowPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'Low\''
    }
  }
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  name: 'NormalPriority'
  location: location
  properties: {
    deadLetteringOnFilterEvaluationExceptions: false
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: '14.00:00:00'
    enableBatchedOperations: false
    lockDuration: '00:00:30'
    maxDeliveryCount: 10
    requiresSession: false
  }
  dependsOn: [
    serviceBusnamespacename
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority_NormalPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  parent: serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority
  name: 'NormalPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'Normal\''
    }
  }
}
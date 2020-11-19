param IncomingDeliveryRequestsTopicname string {
  metadata: {
    description: 'The name for the Service Bus Topic.'
  }
  default: 'incomingdeliveryrequests'
}
param MessageRouterServiceBusnamespacePrefix string {
  metadata: {
    description: 'The prefix of the name for the Service Bus namespace, will be appended with a unique string.'
  }
  default: 'MessageRouterServiceBus'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var serviceBusnamespacename = '${MessageRouterServiceBusnamespacePrefix}-${uniqueString(resourceGroup().id)}'

resource serviceBusnamespacename_resource 'Microsoft.ServiceBus/namespaces@2015-08-01' = {
  name: serviceBusnamespacename
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
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}'
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
  dependsOn: [
    serviceBusnamespacename_resource
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/HighPriority'
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
    serviceBusnamespacename_resource
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority_HighPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/HighPriority/HighPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'High\''
    }
  }
  dependsOn: [
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname_HighPriority
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/Log'
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
    serviceBusnamespacename_resource
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log_LogAll 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/Log/LogAll'
  properties: {
    filter: {
      sqlExpression: '1=1'
    }
  }
  dependsOn: [
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname_Log
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/LowPriority'
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
    serviceBusnamespacename_resource
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority_LowPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/LowPriority/LowPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'Low\''
    }
  }
  dependsOn: [
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname_LowPriority
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/NormalPriority'
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
    serviceBusnamespacename_resource
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname
  ]
}

resource serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority_NormalPriority 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2015-08-01' = {
  name: '${serviceBusnamespacename}/${IncomingDeliveryRequestsTopicname}/NormalPriority/NormalPriority'
  properties: {
    filter: {
      sqlExpression: 'Priority=\'Normal\''
    }
  }
  dependsOn: [
    serviceBusnamespacename_IncomingDeliveryRequestsTopicname_NormalPriority
  ]
}
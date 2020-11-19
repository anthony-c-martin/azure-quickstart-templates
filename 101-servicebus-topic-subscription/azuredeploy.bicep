param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
  }
}
param serviceBusTopicName1 string {
  metadata: {
    description: 'Name of the Topic'
  }
}
param serviceBusTopicName2 string {
  metadata: {
    description: 'Name of the Topic'
  }
}
param serviceBusSubscriptionName string {
  metadata: {
    description: 'Name of the Subscription'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource serviceBusNamespaceName_res 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource serviceBusNamespaceName_serviceBusTopicName1 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName1}'
  properties: {
    path: serviceBusTopicName1
  }
}

resource serviceBusNamespaceName_serviceBusTopicName2 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName2}'
  properties: {
    path: serviceBusTopicName2
  }
}

resource serviceBusNamespaceName_serviceBusTopicName2_serviceBusSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName2}/${serviceBusSubscriptionName}'
  properties: {
    forwardTo: serviceBusTopicName1
    forwardDeadLetteredMessagesTo: serviceBusTopicName1
  }
}
@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Topic')
param serviceBusTopicName1 string

@description('Name of the Topic')
param serviceBusTopicName2 string

@description('Name of the Subscription')
param serviceBusSubscriptionName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource serviceBusNamespaceName_serviceBusTopicName1 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName1}'
  properties: {
    path: serviceBusTopicName1
  }
}

resource serviceBusNamespaceName_serviceBusTopicName2 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName2}'
  properties: {
    path: serviceBusTopicName2
  }
}

resource serviceBusNamespaceName_serviceBusTopicName2_serviceBusSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusTopicName2
  name: serviceBusSubscriptionName
  properties: {
    forwardTo: serviceBusTopicName1
    forwardDeadLetteredMessagesTo: serviceBusTopicName1
  }
  dependsOn: [
    serviceBusNamespaceName_serviceBusTopicName1
  ]
}
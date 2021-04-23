@description('Name of the Service Bus Namespace')
param serviceBusNamespaceName string

@description('Name of the Service Bus Topic')
param serviceBusTopicName string

@description('Name of the Service Bus Topic Subscription')
param serviceBusTopicSubscriptionName string

@description('The SQL Filter of the Service Bus Topic Subscription')
param serviceBusTopicSubscriptionSqlFilter string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName}'
  properties: {
    path: serviceBusTopicName
  }
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusTopicName
  name: serviceBusTopicSubscriptionName
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName_serviceBusTopicSubscriptionName_filter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2017-04-01' = {
  parent: serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName
  name: '${serviceBusTopicSubscriptionName}-filter'
  properties: {
    filter: {
      sqlExpression: serviceBusTopicSubscriptionSqlFilter
    }
  }
}
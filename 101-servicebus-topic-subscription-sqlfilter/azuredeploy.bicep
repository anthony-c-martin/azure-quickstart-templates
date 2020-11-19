param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus Namespace'
  }
}
param serviceBusTopicName string {
  metadata: {
    description: 'Name of the Service Bus Topic'
  }
}
param serviceBusTopicSubscriptionName string {
  metadata: {
    description: 'Name of the Service Bus Topic Subscription'
  }
}
param serviceBusTopicSubscriptionSqlFilter string {
  metadata: {
    description: 'The SQL Filter of the Service Bus Topic Subscription'
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
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName}'
  properties: {
    path: serviceBusTopicName
  }
  dependsOn: [
    serviceBusNamespaceName_res
  ]
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName}/${serviceBusTopicSubscriptionName}'
  dependsOn: [
    serviceBusNamespaceName_serviceBusTopicName
  ]
}

resource serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName_serviceBusTopicSubscriptionName_filter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/Rules@2017-04-01' = {
  name: '${'${serviceBusNamespaceName}/${serviceBusTopicName}'}/${serviceBusTopicSubscriptionName}/${serviceBusTopicSubscriptionName}-filter'
  properties: {
    filter: {
      sqlExpression: serviceBusTopicSubscriptionSqlFilter
    }
  }
  dependsOn: [
    serviceBusNamespaceName_serviceBusTopicName_serviceBusTopicSubscriptionName
  ]
}
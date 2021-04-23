@description('Name of the Service Bus Namespace')
param serviceBusNamespaceName string

@description('Name of the Service Bus Topic')
param serviceBusTopicName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  properties: {}
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName}'
  properties: {
    path: serviceBusTopicName
  }
}
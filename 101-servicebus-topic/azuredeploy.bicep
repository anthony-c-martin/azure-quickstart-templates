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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  properties: {}
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  name: '${serviceBusNamespaceName}/${serviceBusTopicName}'
  properties: {
    path: serviceBusTopicName
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}
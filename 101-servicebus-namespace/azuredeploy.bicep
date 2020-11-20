param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus Namespace'
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
  properties: {}
}
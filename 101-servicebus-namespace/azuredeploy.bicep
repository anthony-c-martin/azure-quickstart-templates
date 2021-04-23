@description('Name of the Service Bus Namespace')
param serviceBusNamespaceName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  properties: {}
}
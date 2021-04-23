@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('The messaging tier for service Bus namespace')
param serviceBusSku string = 'Standard'

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: serviceBusSku
  }
  properties: {}
}
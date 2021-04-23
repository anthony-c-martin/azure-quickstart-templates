@description('Name of Service Bus namespace')
param serviceBusNamespaceNamePrimary string

@description('Name of Service Bus namespace')
param serviceBusNamespaceNameSecondary string

@description('Name of Geo-Recovery Configuration Alias ')
param aliasName string

@description('Location of Secondary namespace')
param locationSecondaryNamepsace string

@description('Location of Primary namespace')
param location string = resourceGroup().location

resource serviceBusNamespaceNameSecondary_resource 'Microsoft.ServiceBus/Namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceNameSecondary
  location: locationSecondaryNamepsace
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 4
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
}

resource serviceBusNamespaceNamePrimary_resource 'Microsoft.ServiceBus/Namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceNamePrimary
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 4
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
  dependsOn: [
    serviceBusNamespaceNameSecondary_resource
  ]
}

resource serviceBusNamespaceNamePrimary_aliasName 'Microsoft.ServiceBus/Namespaces/disasterRecoveryConfigs@2017-04-01' = {
  parent: serviceBusNamespaceNamePrimary_resource
  name: '${aliasName}'
  properties: {
    partnerNamespace: serviceBusNamespaceNameSecondary_resource.id
  }
}
param serviceBusNamespaceNamePrimary string {
  metadata: {
    description: 'Name of Service Bus namespace'
  }
}
param serviceBusNamespaceNameSecondary string {
  metadata: {
    description: 'Name of Service Bus namespace'
  }
}
param aliasName string {
  metadata: {
    description: 'Name of Geo-Recovery Configuration Alias '
  }
}
param locationSecondaryNamepsace string {
  metadata: {
    description: 'Location of Secondary namespace'
  }
}
param location string {
  metadata: {
    description: 'Location of Primary namespace'
  }
  default: resourceGroup().location
}

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
  name: '${serviceBusNamespaceNamePrimary}/${aliasName}'
  properties: {
    partnerNamespace: serviceBusNamespaceNameSecondary_resource.id
  }
  dependsOn: [
    serviceBusNamespaceNamePrimary_resource
  ]
}
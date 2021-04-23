@description('Name of EventHub namespace')
param namespaceName string

@allowed([
  'Basic'
  'Standard'
])
@description('The messaging tier for service Bus namespace')
param eventhubSku string = 'Standard'

@allowed([
  1
  2
  4
])
@description('MessagingUnits for premium namespace')
param skuCapacity int = 1

@description('Name of Event Hub')
param eventHubName string

@description('Name of Consumer Group')
param consumerGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: eventhubSku
    tier: eventhubSku
    capacity: skuCapacity
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
  properties: {}
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: namespaceName_resource
  name: '${eventHubName}'
  properties: {}
}

resource namespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = {
  parent: namespaceName_eventHubName
  name: consumerGroupName
  properties: {
    userMetadata: 'User Metadata goes here'
  }
}
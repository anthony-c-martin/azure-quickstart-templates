param namespaceName string {
  metadata: {
    description: 'Name of EventHub namespace'
  }
}
param eventhubSku string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The messaging tier for service Bus namespace'
  }
  default: 'Standard'
}
param skuCapacity int {
  allowed: [
    1
    2
    4
  ]
  metadata: {
    description: 'MessagingUnits for premium namespace'
  }
  default: 1
}
param eventHubName string {
  metadata: {
    description: 'Name of Event Hub'
  }
}
param consumerGroupName string {
  metadata: {
    description: 'Name of Consumer Group'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource namespaceName_res 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
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
  name: '${namespaceName}/${eventHubName}'
  properties: {}
  dependsOn: [
    namespaceName_res
  ]
}

resource namespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = {
  name: '${namespaceName}/${eventHubName}/${consumerGroupName}'
  properties: {
    userMetadata: 'User Metadata goes here'
  }
  dependsOn: [
    namespaceName_eventHubName
  ]
}
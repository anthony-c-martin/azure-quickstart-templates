@description('Name for the Event Hub cluster.')
param clusterName string

@description('Name for the Event Hub cluster.')
param namespaceName string

@description('Name for the Event Hub to be created in the Event Hub namespace within the Event Hub cluster.')
param eventHubName string

@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

resource clusterName_resource 'Microsoft.EventHub/clusters@2018-01-01-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Dedicated'
    capacity: 1
  }
}

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    clusterArmId: clusterName_resource.id
  }
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: namespaceName_resource
  name: '${eventHubName}'
  location: location
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
}
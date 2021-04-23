@description('Specifies a project name that is used to generate the Event Hub name and the Namespace name.')
param projectName string

@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Basic'
  'Standard'
])
@description('Specifies the messaging tier for Event Hub Namespace.')
param eventHubSku string = 'Standard'

var eventHubNamespaceName_var = '${projectName}ns'
var eventHubName = projectName

resource eventHubNamespaceName 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventHubNamespaceName_var
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: eventHubNamespaceName
  name: '${eventHubName}'
  location: location
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
}
@description('Name of the EventHub namespace ')
param namespaceName string

@allowed([
  'True'
  'False'
])
@description('Enable or disable AutoInflate')
param isAutoInflateEnabled string = 'True'

@minValue(0)
@maxValue(20)
@description('Enable or disable AutoInflate')
param maximumThroughputUnits int = 0

@description('Name of the Event Hub')
param eventHubName string

@minValue(1)
@maxValue(7)
@description('How long to retain the data in Event Hub')
param messageRetentionInDays int = 1

@minValue(2)
@maxValue(32)
@description('Number of partitions chosen')
param partitionCount int = 4

@description('Location for all resources.')
param location string = resourceGroup().location

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', namespaceName, defaultSASKeyName)

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: isAutoInflateEnabled
    maximumThroughputUnits: maximumThroughputUnits
  }
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: namespaceName_resource
  name: '${eventHubName}'
  properties: {
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
  }
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey
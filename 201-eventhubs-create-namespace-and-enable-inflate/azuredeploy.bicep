param namespaceName string {
  metadata: {
    description: 'Name of the EventHub namespace '
  }
}
param isAutoInflateEnabled string {
  allowed: [
    'True'
    'False'
  ]
  metadata: {
    description: 'Enable or disable AutoInflate'
  }
  default: 'True'
}
param maximumThroughputUnits int {
  minValue: 0
  maxValue: 20
  metadata: {
    description: 'Enable or disable AutoInflate'
  }
  default: 0
}
param eventHubName string {
  metadata: {
    description: 'Name of the Event Hub'
  }
}
param messageRetentionInDays int {
  minValue: 1
  maxValue: 7
  metadata: {
    description: 'How long to retain the data in Event Hub'
  }
  default: 1
}
param partitionCount int {
  minValue: 2
  maxValue: 32
  metadata: {
    description: 'Number of partitions chosen'
  }
  default: 4
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', namespaceName, defaultSASKeyName)

resource namespaceName_res 'Microsoft.EventHub/namespaces@2017-04-01' = {
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
  name: '${namespaceName}/${eventHubName}'
  properties: {
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
  }
  dependsOn: [
    namespaceName_res
  ]
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey
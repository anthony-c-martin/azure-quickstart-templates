param namespaceName string {
  metadata: {
    description: 'Name of EventHub namespace'
  }
}
param namespaceAuthorizationRuleName string {
  metadata: {
    description: 'Name of Namespace Authorization Rule'
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
    description: 'Name of Event Hub'
  }
}
param eventhubAuthorizationRuleName string {
  metadata: {
    description: 'Name of Eventhub Authorization Rule'
  }
}
param eventhubAuthorizationRuleName1 string {
  metadata: {
    description: 'Name of Eventhub Authorization Rule'
  }
}
param consumerGroupName string {
  metadata: {
    description: 'Name of Consumer Group'
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
var nsAuthorizationRuleId = namespaceName_namespaceAuthorizationRuleName.id
var ehAuthorizationRuleId1 = resourceId('Microsoft.EventHub/namespaces/eventhubs/authorizationRules', namespaceName, eventHubName, eventhubAuthorizationRuleName)
var ehAuthorizationRuleId2 = resourceId('Microsoft.EventHub/namespaces/eventhubs/authorizationRules', namespaceName, eventHubName, eventhubAuthorizationRuleName1)

resource namespaceName_res 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 7
  }
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  name: '${namespaceName}/${eventHubName}'
  properties: {
    messageRetentionInDays: 4
    partitionCount: 4
  }
}

resource namespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = {
  name: '${namespaceName}/${eventHubName}/${consumerGroupName}'
  properties: {
    userMetadata: 'User Metadata'
  }
}

resource namespaceName_eventHubName_eventhubAuthorizationRuleName 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2017-04-01' = {
  name: '${namespaceName}/${eventHubName}/${eventhubAuthorizationRuleName}'
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
}

resource namespaceName_eventHubName_eventhubAuthorizationRuleName1 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2017-04-01' = {
  name: '${namespaceName}/${eventHubName}/${eventhubAuthorizationRuleName1}'
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource namespaceName_namespaceAuthorizationRuleName 'Microsoft.EventHub/namespaces/AuthorizationRules@2017-04-01' = {
  name: '${namespaceName}/${namespaceAuthorizationRuleName}'
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
}

output defaultNamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output defaultSharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey
output NamespaceConnectionString string = listkeys(nsAuthorizationRuleId, '2017-04-01').primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(nsAuthorizationRuleId, '2017-04-01').primaryKey
output EventHubConnectionString string = listkeys(ehAuthorizationRuleId1, '2017-04-01').primaryConnectionString
output EventHubSharedAccessPolicyPrimaryKey string = listkeys(ehAuthorizationRuleId1, '2017-04-01').primaryKey
output EventHub1ConnectionString string = listkeys(ehAuthorizationRuleId2, '2017-04-01').primaryConnectionString
output EventHub1SharedAccessPolicyPrimaryKey string = listkeys(ehAuthorizationRuleId2, '2017-04-01').primaryKey
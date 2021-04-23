@description('Name of EventHub namespace')
param namespaceName string

@description('Name of Namespace Authorization Rule')
param namespaceAuthorizationRuleName string

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

@description('Name of Event Hub')
param eventHubName string

@description('Name of Eventhub Authorization Rule')
param eventhubAuthorizationRuleName string

@description('Name of Eventhub Authorization Rule')
param eventhubAuthorizationRuleName1 string

@description('Name of Consumer Group')
param consumerGroupName string

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
var nsAuthorizationRuleId = namespaceName_namespaceAuthorizationRuleName.id
var ehAuthorizationRuleId1 = namespaceName_eventHubName_eventhubAuthorizationRuleName.id
var ehAuthorizationRuleId2 = namespaceName_eventHubName_eventhubAuthorizationRuleName1.id

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2017-04-01' = {
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
  parent: namespaceName_resource
  name: '${eventHubName}'
  properties: {
    messageRetentionInDays: 4
    partitionCount: 4
  }
}

resource namespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = {
  parent: namespaceName_eventHubName
  name: consumerGroupName
  properties: {
    userMetadata: 'User Metadata'
  }
}

resource namespaceName_eventHubName_eventhubAuthorizationRuleName 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2017-04-01' = {
  parent: namespaceName_eventHubName
  name: eventhubAuthorizationRuleName
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
}

resource namespaceName_eventHubName_eventhubAuthorizationRuleName1 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2017-04-01' = {
  parent: namespaceName_eventHubName
  name: eventhubAuthorizationRuleName1
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource namespaceName_namespaceAuthorizationRuleName 'Microsoft.EventHub/namespaces/AuthorizationRules@2017-04-01' = {
  parent: namespaceName_resource
  name: '${namespaceAuthorizationRuleName}'
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
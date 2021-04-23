@description('Name of Event Hub namespace')
param eventHubNamespaceNamePrimary string

@description('Name of Event Hub namespace')
param eventHubNamespaceNameSecondary string

@description('Name of Geo-Recovery Configuration Alias')
param aliasName string

@allowed([
  'Basic'
  'Standard'
])
@description('The messaging tier for Event Hub namespace')
param eventhubSku string = 'Standard'

@allowed([
  1
  2
  4
])
@description('MessagingUnits for namespace')
param skuCapacity int = 1

@description('Location of Primary namespace')
param locationPrimaryNamepsace string = 'northcentralus'

@description('Location of Secondary namespace')
param locationSecondaryNamepsace string = 'southcentralus'

var defaultSASKeyName = 'RootManageSharedAccessKey'
var defaultAuthRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceNamePrimary, defaultSASKeyName)

resource eventHubNamespaceNameSecondary_resource 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: eventHubNamespaceNameSecondary
  location: locationSecondaryNamepsace
  sku: {
    name: eventhubSku
    tier: eventhubSku
    capacity: skuCapacity
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
}

resource eventHubNamespaceNamePrimary_resource 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: eventHubNamespaceNamePrimary
  location: locationPrimaryNamepsace
  sku: {
    name: eventhubSku
    tier: eventhubSku
    capacity: skuCapacity
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
  dependsOn: [
    eventHubNamespaceNameSecondary_resource
  ]
}

resource eventHubNamespaceNamePrimary_aliasName 'Microsoft.EventHub/namespaces/disasterRecoveryConfigs@2017-04-01' = {
  parent: eventHubNamespaceNamePrimary_resource
  name: '${aliasName}'
  properties: {
    partnerNamespace: eventHubNamespaceNameSecondary_resource.id
  }
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, '2017-04-01').primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, '2017-04-01').primaryKey
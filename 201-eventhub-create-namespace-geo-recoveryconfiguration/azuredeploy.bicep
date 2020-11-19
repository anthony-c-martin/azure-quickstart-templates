param eventHubNamespaceNamePrimary string {
  metadata: {
    description: 'Name of Event Hub namespace'
  }
}
param eventHubNamespaceNameSecondary string {
  metadata: {
    description: 'Name of Event Hub namespace'
  }
}
param aliasName string {
  metadata: {
    description: 'Name of Geo-Recovery Configuration Alias'
  }
}
param eventhubSku string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The messaging tier for Event Hub namespace'
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
    description: 'MessagingUnits for namespace'
  }
  default: 1
}
param locationPrimaryNamepsace string {
  metadata: {
    description: 'Location of Primary namespace'
  }
  default: 'northcentralus'
}
param locationSecondaryNamepsace string {
  metadata: {
    description: 'Location of Secondary namespace'
  }
  default: 'southcentralus'
}

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
  name: '${eventHubNamespaceNamePrimary}/${aliasName}'
  properties: {
    partnerNamespace: eventHubNamespaceNameSecondary_resource.id
  }
  dependsOn: [
    eventHubNamespaceNamePrimary_resource
  ]
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, '2017-04-01').primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, '2017-04-01').primaryKey
param premiumNamespaceName string {
  metadata: {
    description: 'Name of the Event Hub namespace'
  }
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
param namespaceSASKeyName string {
  metadata: {
    description: 'Name of the Namespace AuthorizationRule'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var ehVersion = '2017-04-01'
var defaultSASKeyName = 'RootManageSharedAccessKey'
var customSASKeyName = concat(premiumNamespaceName, '/${namespaceSASKeyName}')
var defaultAuthRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', premiumNamespaceName, defaultSASKeyName)
var customAuthRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', premiumNamespaceName, namespaceSASKeyName)

resource premiumNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: premiumNamespaceName
  location: location
  kind: 'Messaging'
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: skuCapacity
  }
  properties: {
    createACSNamespace: true
  }
}

resource customSASKeyName_resource 'Microsoft.ServiceBus/namespaces/authorizationRules@2017-04-01' = {
  name: customSASKeyName
  location: location
  properties: {
    Rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
  dependsOn: [
    premiumNamespaceName_resource
  ]
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryKey
output NamespaceCustomConnectionString string = listkeys(customAuthRuleResourceId, ehVersion).primaryConnectionString
output CustomSharedAccessPolicyPrimaryKey string = listkeys(customAuthRuleResourceId, ehVersion).primaryKey
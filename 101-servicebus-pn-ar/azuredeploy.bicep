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
var customSASKeyName_var = concat(premiumNamespaceName, '/${namespaceSASKeyName}')
var defaultAuthRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', premiumNamespaceName, defaultSASKeyName)
var customAuthRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', premiumNamespaceName, namespaceSASKeyName)

resource premiumNamespaceName_res 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
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

resource customSASKeyName 'Microsoft.ServiceBus/namespaces/authorizationRules@2017-04-01' = {
  name: customSASKeyName_var
  location: location
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
  dependsOn: [
    premiumNamespaceName_res
  ]
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryKey
output NamespaceCustomConnectionString string = listkeys(customAuthRuleResourceId, ehVersion).primaryConnectionString
output CustomSharedAccessPolicyPrimaryKey string = listkeys(customAuthRuleResourceId, ehVersion).primaryKey
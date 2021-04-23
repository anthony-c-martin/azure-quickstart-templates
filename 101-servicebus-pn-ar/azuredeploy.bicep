@description('Name of the Event Hub namespace')
param premiumNamespaceName string

@allowed([
  1
  2
  4
])
@description('MessagingUnits for premium namespace')
param skuCapacity int = 1

@description('Name of the Namespace AuthorizationRule')
param namespaceSASKeyName string

@description('Location for all resources.')
param location string = resourceGroup().location

var ehVersion = '2017-04-01'
var defaultSASKeyName = 'RootManageSharedAccessKey'
var customSASKeyName_var = '${premiumNamespaceName}/${namespaceSASKeyName}'
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
    premiumNamespaceName_resource
  ]
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, ehVersion).primaryKey
output NamespaceCustomConnectionString string = listkeys(customAuthRuleResourceId, ehVersion).primaryConnectionString
output CustomSharedAccessPolicyPrimaryKey string = listkeys(customAuthRuleResourceId, ehVersion).primaryKey
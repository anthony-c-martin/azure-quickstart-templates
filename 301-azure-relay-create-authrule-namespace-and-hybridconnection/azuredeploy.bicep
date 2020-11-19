param namespaceName string {
  metadata: {
    description: 'Name of the Azure Relay namespace'
  }
}
param namespaceAuthorizationRuleName string {
  metadata: {
    description: 'Name of the Namespace AuthorizationRule'
  }
}
param hybridConnectionName string {
  metadata: {
    description: 'Name of the HybridConnection'
  }
}
param hybridConnectionAuthorizationRuleName string {
  metadata: {
    description: 'Name of the HybridConnection AuthorizationRule'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var location_variable = location
var apiVersion = '2017-04-01'
var namespaceAuthRuleName = concat(namespaceName, '/${namespaceAuthorizationRuleName}')
var nsAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, namespaceAuthorizationRuleName)
var hcAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/HybridConnections/authorizationRules', namespaceName, hybridConnectionName, hybridConnectionAuthorizationRuleName)

resource namespaceName_resource 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: namespaceName
  location: location_variable
  kind: 'Relay'
}

resource namespaceName_hybridConnectionName 'Microsoft.Relay/Namespaces/HybridConnections@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${hybridConnectionName}'
  properties: {
    requiresClientAuthorization: 'true'
    userMetadata: 'Meta Data supplied by user hybridConnections'
  }
  dependsOn: [
    namespaceName_resource
  ]
}

resource namespaceName_hybridConnectionName_hybridConnectionAuthorizationRuleName 'Microsoft.Relay/Namespaces/HybridConnections/authorizationRules@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${hybridConnectionName}/${hybridConnectionAuthorizationRuleName}'
  properties: {
    Rights: [
      'Listen'
    ]
  }
  dependsOn: [
    namespaceName_hybridConnectionName
  ]
}

resource namespaceAuthRuleName_resource 'Microsoft.Relay/namespaces/authorizationRules@[variables(\'apiVersion\')]' = {
  name: namespaceAuthRuleName
  properties: {
    Rights: [
      'Send'
    ]
  }
  dependsOn: [
    namespaceName_resource
  ]
}

output NamespaceConnectionString string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output NamespaceSharedAccessPolicyPrimaryKey string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryKey
output HybridConnectionConnectionString string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output HybridConnectionSharedAccessPolicyPrimaryKey string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryKey
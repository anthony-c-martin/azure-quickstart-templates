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

var location_var = location
var apiVersion = '2017-04-01'
var namespaceAuthRuleName_var = concat(namespaceName, '/${namespaceAuthorizationRuleName}')
var nsAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, namespaceAuthorizationRuleName)
var hcAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/HybridConnections/authorizationRules', namespaceName, hybridConnectionName, hybridConnectionAuthorizationRuleName)

resource namespaceName_res 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: namespaceName
  location: location_var
  kind: 'Relay'
}

resource namespaceName_hybridConnectionName 'Microsoft.Relay/Namespaces/HybridConnections@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${hybridConnectionName}'
  properties: {
    requiresClientAuthorization: 'true'
    userMetadata: 'Meta Data supplied by user hybridConnections'
  }
}

resource namespaceName_hybridConnectionName_hybridConnectionAuthorizationRuleName 'Microsoft.Relay/Namespaces/HybridConnections/authorizationRules@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${hybridConnectionName}/${hybridConnectionAuthorizationRuleName}'
  properties: {
    Rights: [
      'Listen'
    ]
  }
}

resource namespaceAuthRuleName 'Microsoft.Relay/namespaces/authorizationRules@[variables(\'apiVersion\')]' = {
  name: namespaceAuthRuleName_var
  properties: {
    Rights: [
      'Send'
    ]
  }
}

output NamespaceConnectionString string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output NamespaceSharedAccessPolicyPrimaryKey string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryKey
output HybridConnectionConnectionString string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output HybridConnectionSharedAccessPolicyPrimaryKey string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryKey
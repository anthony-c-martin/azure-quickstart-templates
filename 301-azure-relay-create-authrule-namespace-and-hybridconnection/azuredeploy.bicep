@description('Name of the Azure Relay namespace')
param namespaceName string

@description('Name of the Namespace AuthorizationRule')
param namespaceAuthorizationRuleName string

@description('Name of the HybridConnection')
param hybridConnectionName string

@description('Name of the HybridConnection AuthorizationRule')
param hybridConnectionAuthorizationRuleName string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var apiVersion = '2017-04-01'
var namespaceAuthRuleName_var = '${namespaceName}/${namespaceAuthorizationRuleName}'
var nsAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, namespaceAuthorizationRuleName)
var hcAuthorizationRuleResourceId = namespaceName_hybridConnectionName_hybridConnectionAuthorizationRuleName.id

resource namespaceName_resource 'Microsoft.Relay/Namespaces@2017-04-01' = {
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

resource namespaceAuthRuleName 'Microsoft.Relay/namespaces/authorizationRules@[variables(\'apiVersion\')]' = {
  name: namespaceAuthRuleName_var
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
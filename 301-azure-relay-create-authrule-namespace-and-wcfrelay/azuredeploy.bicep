@description('Name of the Azure Relay namespace')
param namespaceName string

@description('Name of the Namespace AuthorizationRule')
param namespaceAuthorizationRuleName string

@description('Name of the WcfRelay')
param wcfrelayName string

@allowed([
  'NetTcp'
  'Http'
])
@description('WCF Relay Type. It could be any of the types: NetTcp/Http')
param wcfRelayType string

@description('Name of the WcfRelay AuthorizationRule')
param wcfrelayAuthorizationRuleName string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var apiVersion = '2017-04-01'
var namespaceAuthRuleName_var = '${namespaceName}/${namespaceAuthorizationRuleName}'
var nsAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, namespaceAuthorizationRuleName)
var hcAuthorizationRuleResourceId = namespaceName_wcfrelayName_wcfrelayAuthorizationRuleName.id

resource namespaceName_resource 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: namespaceName
  location: location_var
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource namespaceName_wcfrelayName 'Microsoft.Relay/Namespaces/WcfRelays@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${wcfrelayName}'
  properties: {
    relayType: wcfRelayType
    requiresClientAuthorization: 'false'
    requiresTransportSecurity: 'false'
    userMetadata: 'Meta Data supplied by user for wcfRelays'
  }
  dependsOn: [
    namespaceName_resource
  ]
}

resource namespaceName_wcfrelayName_wcfrelayAuthorizationRuleName 'Microsoft.Relay/Namespaces/WcfRelays/authorizationRules@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${wcfrelayName}/${wcfrelayAuthorizationRuleName}'
  properties: {
    Rights: [
      'Listen'
    ]
  }
  dependsOn: [
    namespaceName_wcfrelayName
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
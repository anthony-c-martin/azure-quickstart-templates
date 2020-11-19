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
param wcfrelayName string {
  metadata: {
    description: 'Name of the WcfRelay'
  }
}
param wcfRelayType string {
  allowed: [
    'NetTcp'
    'Http'
  ]
  metadata: {
    description: 'WCF Relay Type. It could be any of the types: NetTcp/Http'
  }
}
param wcfrelayAuthorizationRuleName string {
  metadata: {
    description: 'Name of the WcfRelay AuthorizationRule'
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
var hcAuthorizationRuleResourceId = resourceId('Microsoft.Relay/namespaces/WcfRelays/authorizationRules', namespaceName, wcfrelayName, wcfrelayAuthorizationRuleName)

resource namespaceName_res 'Microsoft.Relay/Namespaces@2017-04-01' = {
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
    namespaceName_res
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
    namespaceName_res
  ]
}

output NamespaceConnectionString string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output NamespaceSharedAccessPolicyPrimaryKey string = listkeys(nsAuthorizationRuleResourceId, apiVersion).primaryKey
output HybridConnectionConnectionString string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryConnectionString
output HybridConnectionSharedAccessPolicyPrimaryKey string = listkeys(hcAuthorizationRuleResourceId, apiVersion).primaryKey
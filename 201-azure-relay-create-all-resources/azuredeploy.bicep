@description('Name of the Azure Relay namespace')
param namespaceName string

@description('Name of the WCF Relay')
param wcfRelayName string

@allowed([
  'NetTcp'
  'Http'
])
@description('WCF Relay Type. It could be any of the types: NetTcp/Http')
param wcfRelayType string

@description('Name of the HybridConnection')
param hybridConnectionName string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var apiVersion = '2017-04-01'
var defaultSASKeyName = 'RootManageSharedAccessKey'
var defaultAuthRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, defaultSASKeyName)

resource namespaceName_resource 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: namespaceName
  location: location_var
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource namespaceName_wcfRelayName 'Microsoft.Relay/Namespaces/wcfRelays@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${wcfRelayName}'
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

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, apiVersion).primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, apiVersion).primaryKey
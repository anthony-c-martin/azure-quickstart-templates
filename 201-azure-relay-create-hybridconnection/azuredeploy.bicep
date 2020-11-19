param namespaceName string {
  metadata: {
    description: 'Name of the Azure Relay namespace'
  }
}
param hybridConnectionName string {
  metadata: {
    description: 'Name of the HybridConnection'
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
var defaultSASKeyName = 'RootManageSharedAccessKey'
var defaultAuthRuleResourceId = resourceId('Microsoft.Relay/namespaces/authorizationRules', namespaceName, defaultSASKeyName)

resource namespaceName_res 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: namespaceName
  location: location_var
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource namespaceName_hybridConnectionName 'Microsoft.Relay/Namespaces/HybridConnections@[variables(\'apiVersion\')]' = {
  name: '${namespaceName}/${hybridConnectionName}'
  properties: {
    requiresClientAuthorization: 'true'
    userMetadata: 'Meta Data supplied by user for hybridConnections'
  }
  dependsOn: [
    namespaceName_res
  ]
}

output NamespaceDefaultConnectionString string = listkeys(defaultAuthRuleResourceId, apiVersion).primaryConnectionString
output DefaultSharedAccessPolicyPrimaryKey string = listkeys(defaultAuthRuleResourceId, apiVersion).primaryKey
@description('The name of the SQL logical server.')
param serverName string = uniqueString('sql', resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

@description('Enable Advanced Data Security, the user deploying the template must have an administrator or owner permissions.')
param enableADS bool = true

@description('Allow Azure services to access server.')
param allowAzureIPs bool = true

@allowed([
  'Default'
  'Redirect'
  'Proxy'
])
@description('SQL logical server connection type.')
param connectionType string = 'Default'

var serverResourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var uniqueStorage = uniqueString(subscriptionId, serverResourceGroupName, location)
var storageName_var = toLower('sqlva${uniqueStorage}')
var uniqueRoleGuid_var = guid(storageName.id, StorageBlobContributor, serverName_resource.id)
var StorageBlobContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource serverName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: serverName
  location: location
  identity: (enableADS ? json('{"type":"SystemAssigned"}') : json('null'))
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
  }
}

resource serverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2020-02-02-preview' = if (allowAzureIPs) {
  parent: serverName_resource
  name: 'AllowAllWindowsAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource serverName_Default 'Microsoft.Sql/servers/securityAlertPolicies@2020-02-02-preview' = if (enableADS) {
  parent: serverName_resource
  name: 'Default'
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
  }
}

resource Microsoft_Sql_servers_vulnerabilityAssessments_serverName_Default 'Microsoft.Sql/servers/vulnerabilityAssessments@2020-02-02-preview' = if (enableADS) {
  parent: serverName_resource
  name: 'Default'
  properties: {
    storageContainerPath: (enableADS ? '${storageName.properties.primaryEndpoints.blob}vulnerability-assessment' : json('null'))
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
    }
  }
  dependsOn: [
    serverName_Default
  ]
}

resource Microsoft_Sql_servers_connectionPolicies_serverName_Default 'Microsoft.Sql/servers/connectionPolicies@2014-04-01' = {
  parent: serverName_resource
  name: 'Default'
  properties: {
    connectionType: connectionType
  }
}

resource storageName 'Microsoft.Storage/storageAccounts@2019-06-01' = if (enableADS) {
  name: storageName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource uniqueRoleGuid 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (enableADS) {
  name: uniqueRoleGuid_var
  properties: {
    roleDefinitionId: StorageBlobContributor
    principalId: reference(serverName_resource.id, '2020-02-02-preview', 'Full').identity.principalId
    scope: storageName.id
    principalType: 'ServicePrincipal'
  }
  scope: storageName
}
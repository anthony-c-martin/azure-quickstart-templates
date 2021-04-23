@description('Name of the SQL server')
param sqlServerName string = 'sql-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL Server.')
param sqlAdministratorLogin string

@description('The administrator password of the SQL Server.')
@secure()
param sqlAdministratorLoginPassword string

@description('The name of the auditing storage account.')
param storageAccountName string = 'sqlaudit${uniqueString(resourceGroup().id)}'

@description('Enable Auditing to storage behind Virtual Network or firewall rules. The user deploying the template must have an administrator or owner permissions.')
param isStorageBehindVnet bool = false

@description('Enable Auditing of Microsoft support operations (DevOps)')
param isMSDevOpsAuditEnabled bool = false

var StorageBlobContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var uniqueRoleGuid = guid(storageAccountName_resource.id, StorageBlobContributor, sqlServerName_resource.id)

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: (isStorageBehindVnet ? 'Deny' : 'Allow')
    }
  }
}

resource storageAccountName_Microsoft_Authorization_uniqueRoleGuid 'Microsoft.Storage/storageAccounts/providers/roleAssignments@2020-03-01-preview' = if (isStorageBehindVnet) {
  name: '${storageAccountName}/Microsoft.Authorization/${uniqueRoleGuid}'
  properties: {
    roleDefinitionId: StorageBlobContributor
    principalId: reference(sqlServerName_resource.id, '2020-08-01-preview', 'Full').identity.principalId
    scope: storageAccountName_resource.id
    principalType: 'ServicePrincipal'
  }
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-08-01-preview' = {
  location: location
  name: sqlServerName
  identity: (isStorageBehindVnet ? json('{"type":"SystemAssigned"}') : json('null'))
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
  tags: {
    displayName: sqlServerName
  }
}

resource sqlServerName_DefaultAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2019-06-01-preview' = {
  parent: sqlServerName_resource
  name: 'DefaultAuditingSettings'
  properties: {
    state: 'Enabled'
    storageEndpoint: reference(storageAccountName_resource.id, '2019-06-01').PrimaryEndpoints.Blob
    storageAccountAccessKey: (isStorageBehindVnet ? json('null') : listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value)
    storageAccountSubscriptionId: subscription().subscriptionId
    isStorageSecondaryKeyInUse: false
  }
  dependsOn: [
    extensionResourceId(storageAccountName_resource.id, 'Microsoft.Authorization/roleAssignments/', uniqueRoleGuid)
  ]
}

resource sqlServerName_Default 'Microsoft.Sql/servers/devOpsAuditingSettings@2020-08-01-preview' = if (isMSDevOpsAuditEnabled) {
  parent: sqlServerName_resource
  name: 'Default'
  properties: {
    state: 'Enabled'
    storageEndpoint: reference(storageAccountName_resource.id, '2019-06-01').PrimaryEndpoints.Blob
    storageAccountAccessKey: (isStorageBehindVnet ? json('null') : listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value)
    storageAccountSubscriptionId: subscription().subscriptionId
    isStorageSecondaryKeyInUse: false
  }
  dependsOn: [
    storageAccountName_Microsoft_Authorization_uniqueRoleGuid
  ]
}
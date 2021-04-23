param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceStorageAccountContributorRoleName ? /* TODO: fill in correct type */
param variables_workspaceStorageAccount ? /* TODO: fill in correct type */
param variables_contributorRoleDefinition ? /* TODO: fill in correct type */
param variables_workspaceStorageAccountBlobDataContributorRoleName ? /* TODO: fill in correct type */
param variables_storageBlobDataContributorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign AML workspace storage account permissions.')
param assignWorkspaceStorageAccount bool

@description('Resource name of AML workspace storage account.')
param workspaceStorageAccountName string

resource variables_workspaceStorageAccountContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceStorageAccount) {
  name: variables_workspaceStorageAccountContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceStorageAccount, 'Microsoft.Authorization/roleDefinitions', variables_contributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.Storage/storageAccounts/${workspaceStorageAccountName}'
}

resource variables_workspaceStorageAccountBlobDataContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceStorageAccount) {
  name: variables_workspaceStorageAccountBlobDataContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceStorageAccount, 'Microsoft.Authorization/roleDefinitions', variables_storageBlobDataContributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.Storage/storageAccounts/${workspaceStorageAccountName}'
}
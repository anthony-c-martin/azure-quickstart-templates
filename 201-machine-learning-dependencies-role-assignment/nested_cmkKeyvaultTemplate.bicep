param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceCMKKeyVaultContributorRoleName ? /* TODO: fill in correct type */
param variables_workspaceCMKKeyVault ? /* TODO: fill in correct type */
param variables_contributorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign keyvault that hosts data encryption key of cmk workspace permissions.')
param assignWorkspaceCMKKeyVault bool

@description('Resource name of keyvault that hosts data encryption key of cmk workspace.')
param workspaceCMKKeyVaultName string

resource variables_workspaceCMKKeyVaultContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceCMKKeyVault) {
  name: variables_workspaceCMKKeyVaultContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceCMKKeyVault, 'Microsoft.Authorization/roleDefinitions', variables_contributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.KeyVault/vaults/${workspaceCMKKeyVaultName}'
}
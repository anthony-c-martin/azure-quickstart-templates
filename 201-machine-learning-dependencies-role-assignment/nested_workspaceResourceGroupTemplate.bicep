param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceResourceGroupContributorRoleName ? /* TODO: fill in correct type */
param variables_workspaceResourceGroup ? /* TODO: fill in correct type */
param variables_contributorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign AML workspace resource group permissions.')
param assignWorkspaceResourceGroup bool

resource variables_workspaceResourceGroupContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceResourceGroup) {
  name: variables_workspaceResourceGroupContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceResourceGroup, 'Microsoft.Authorization/roleDefinitions', variables_contributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
}
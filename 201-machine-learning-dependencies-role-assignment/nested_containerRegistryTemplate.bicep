param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceContainerRegistryContributorRoleName ? /* TODO: fill in correct type */
param variables_workspaceContainerRegistry ? /* TODO: fill in correct type */
param variables_contributorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign AML workspace container registry permissions.')
param assignWorkspaceContainerRegistry bool

@description('Resource name of AML workspace container registry.')
param workspaceContainerRegistryName string

resource variables_workspaceContainerRegistryContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceContainerRegistry) {
  name: variables_workspaceContainerRegistryContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceContainerRegistry, 'Microsoft.Authorization/roleDefinitions', variables_contributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.ContainerRegistry/registries/${workspaceContainerRegistryName}'
}
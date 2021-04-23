param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceDataBrickContributorRoleName ? /* TODO: fill in correct type */
param variables_workspaceDataBrick ? /* TODO: fill in correct type */
param variables_contributorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign AML workspace linked Azure DataBrick permissions.')
param assignWorkspaceDataBrick bool

@description('Resource name of AML workspace linked Azure DataBrick.')
param workspaceDataBrickName string

resource variables_workspaceDataBrickContributorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceDataBrick) {
  name: variables_workspaceDataBrickContributorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceDataBrick, 'Microsoft.Authorization/roleDefinitions', variables_contributorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.Databricks/workspaces/${workspaceDataBrickName}'
}
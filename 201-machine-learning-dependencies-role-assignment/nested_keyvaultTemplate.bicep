param reference_variables_primaryUserAssignedIdentity_2018_11_30_tenantId object
param reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId object
param variables_workspaceKeyVaultAdministratorRoleName ? /* TODO: fill in correct type */
param variables_workspaceKeyVault ? /* TODO: fill in correct type */
param variables_keyVaultAdministratorRoleDefinition ? /* TODO: fill in correct type */

@description('If assign AML workspace keyvault permissions.')
param assignWorkspaceKeyVault bool

@description('Resource name of AML workspace key vault.')
param workspaceKeyVaultName string

resource workspaceKeyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = if (assignWorkspaceKeyVault) {
  name: '${workspaceKeyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: reference_variables_primaryUserAssignedIdentity_2018_11_30_tenantId.tenantId
        objectId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
        }
      }
    ]
  }
}

resource variables_workspaceKeyVaultAdministratorRoleName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (assignWorkspaceKeyVault) {
  name: variables_workspaceKeyVaultAdministratorRoleName
  properties: {
    roleDefinitionId: extensionResourceId(variables_workspaceKeyVault, 'Microsoft.Authorization/roleDefinitions', variables_keyVaultAdministratorRoleDefinition)
    principalId: reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId.principalId
    principalType: 'ServicePrincipal'
  }
  scope: 'Microsoft.KeyVault/vaults/${workspaceKeyVaultName}'
}
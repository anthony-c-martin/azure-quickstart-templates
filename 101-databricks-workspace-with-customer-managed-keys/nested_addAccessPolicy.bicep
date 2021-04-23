param resourceId_Microsoft_Databricks_workspaces_parameters_workspaceName object

@description('The Azure Key Vault name.')
param keyVaultName string

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: resourceId_Microsoft_Databricks_workspaces_parameters_workspaceName.storageAccountIdentity.principalId
        tenantId: resourceId_Microsoft_Databricks_workspaces_parameters_workspaceName.storageAccountIdentity.tenantId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
    ]
  }
}
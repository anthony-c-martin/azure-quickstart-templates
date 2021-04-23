param resourceId_Microsoft_Sql_servers_parameters_sqlServerName object

@description('Key vault name where the key to use is stored')
param keyVaultName string

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: resourceId_Microsoft_Sql_servers_parameters_sqlServerName.identity.principalId
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
param keyVaultName string {
  metadata: {
    description: 'Specifies the name of the key vault.'
  }
}
param tenantId string {
  metadata: {
    description: 'Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.'
  }
  default: subscription().tenantId
}
param objectId string {
  metadata: {
    description: 'Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.'
  }
}
param secretsPermissions array {
  metadata: {
    description: 'Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.'
  }
  default: [
    'list'
  ]
}

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: secretsPermissions
        }
      }
    ]
  }
}
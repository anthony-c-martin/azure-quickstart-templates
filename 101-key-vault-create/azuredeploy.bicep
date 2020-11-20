param keyVaultName string {
  metadata: {
    description: 'Specifies the name of the key vault.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
  default: resourceGroup().location
}
param enabledForDeployment bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.'
  }
  default: false
}
param enabledForDiskEncryption bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.'
  }
  default: false
}
param enabledForTemplateDeployment bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.'
  }
  default: false
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
param keysPermissions array {
  metadata: {
    description: 'Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.'
  }
  default: [
    'list'
  ]
}
param secretsPermissions array {
  metadata: {
    description: 'Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.'
  }
  default: [
    'list'
  ]
}
param skuName string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Specifies whether the key vault is a standard vault or a premium vault.'
  }
  default: 'Standard'
}
param secretName string {
  metadata: {
    description: 'Specifies the name of the secret that you want to create.'
  }
}
param secretValue string {
  metadata: {
    description: 'Specifies the value of the secret that you want to create.'
  }
  secure: true
}

resource keyVaultName_res 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource keyVaultName_secretName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/${secretName}'
  location: location
  properties: {
    value: secretValue
  }
  dependsOn: [
    keyVaultName_res
  ]
}
@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'all'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'all'
]

@allowed([
  'Standard'
  'Premium'
])
@description('Specifies the SKU for the key vault')
param vaultSku string = 'Standard'

@minValue(0)
@maxValue(365)
@description('Specifies the number of days that logs are gonna be kept. If you do not want to apply any retention policy and retain data forever, set value to 0.')
param logsRetentionInDays int = 0

@description('Determines if the resources should be locked to prevent deletion.')
param protectWithLocks bool = true

var uniqueString = uniqueString(subscription().id, resourceGroup().id)
var diagnosticStorageAccountName_var = toLower(substring(replace(concat(keyVaultName, uniqueString, uniqueString), '-', ''), 0, 23))

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: 'Key Vault with logging'
  }
  properties: {
    sku: {
      name: vaultSku
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: subscription().tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
  }
}

resource diagnosticStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: diagnosticStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    displayName: 'concat(\'Key Vault \', parameters(\'keyVaultName\'), \' diagnostics storage account\')'
  }
}

resource service 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'service'
  location: location
  properties: {
    storageAccountId: diagnosticStorageAccountName.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logsRetentionInDays
        }
      }
    ]
  }
  scope: keyVaultName_resource
  dependsOn: [
    keyVaultName_resource
  ]
}

resource keyVaultDoNotDelete 'Microsoft.Authorization/locks@2017-04-01' = if (protectWithLocks) {
  name: 'keyVaultDoNotDelete'
  properties: {
    level: 'CannotDelete'
  }
  scope: keyVaultName_resource
  dependsOn: [
    keyVaultName_resource
  ]
}

resource storageDoNotDelete 'Microsoft.Authorization/locks@2017-04-01' = if (protectWithLocks) {
  name: 'storageDoNotDelete'
  properties: {
    level: 'CannotDelete'
  }
  scope: diagnosticStorageAccountName
  dependsOn: [
    diagnosticStorageAccountName
  ]
}
param keyVaultName string {
  metadata: {
    description: 'Specifies the name of the key vault.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the location for all resources.'
  }
  default: resourceGroup().location
}
param enableVaultForDeployment bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.'
  }
  default: false
}
param enableVaultForTemplateDeployment bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.'
  }
  default: false
}
param enableVaultForDiskEncryption bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.'
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
    'all'
  ]
}
param secretsPermissions array {
  metadata: {
    description: 'Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.'
  }
  default: [
    'all'
  ]
}
param vaultSku string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Specifies the SKU for the key vault'
  }
  default: 'Standard'
}
param logsRetentionInDays int {
  minValue: 0
  maxValue: 365
  metadata: {
    description: 'Specifies the number of days that logs are gonna be kept. If you do not want to apply any retention policy and retain data forever, set value to 0.'
  }
  default: 0
}
param protectWithLocks string {
  allowed: [
    'enabled'
    'disabled'
  ]
  default: 'disabled'
}
param artifactsLocation string {
  metadata: {
    description: 'The location of resources, such as templates and DSC modules, that the template depends on'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-key-vault-with-logging-create/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'Auto-generated token to access _artifactsLocation'
  }
  secure: true
  default: ''
}

var template = {
  protectWithLocks: 'nestedtemplates/protectwithlocks${protectWithLocks}.json'
}
var uniqueString = uniqueString(subscription().id, resourceGroup().id)
var diagnosticStorageAccountName_var = toLower(substring(replace(concat(keyVaultName, uniqueString, uniqueString), '-', ''), 0, 23))

resource keyVaultName_res 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: 'Key Vault with logging'
  }
  properties: {
    enabledForDeployment: enableVaultForDeployment
    enabledForTemplateDeployment: enableVaultForTemplateDeployment
    enabledForDiskEncryption: enableVaultForDiskEncryption
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
      name: vaultSku
      family: 'A'
    }
  }
}

resource keyVaultName_Microsoft_Insights_service 'Microsoft.KeyVault/vaults/providers/diagnosticsettings@2016-09-01' = {
  name: '${keyVaultName}/Microsoft.Insights/service'
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
  dependsOn: [
    keyVaultName_res
  ]
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

module protectWithLocks_res '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat(variables('template').protectWithLocks, parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'protectWithLocks'
  params: {
    keyVaultName: keyVaultName
    diagnosticStorageAccountName: diagnosticStorageAccountName_var
  }
  dependsOn: [
    keyVaultName_res
    diagnosticStorageAccountName
  ]
}
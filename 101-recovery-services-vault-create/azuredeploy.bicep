@description('Name of the Vault')
param vaultName string

@description('Change Vault Storage Type Selection (Works if vault has not registered any backup instance)')
param changeStorageType bool = false

@allowed([
  'LocallyRedundant'
  'GeoRedundant'
])
@description('Change Vault Storage Type (not allowed if the vault has registered backups)')
param vaultStorageType string = 'GeoRedundant'

@description('Location for all resources.')
param location string = resourceGroup().location

var skuName = 'RS0'
var skuTier = 'Standard'

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2020-02-02' = {
  name: vaultName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {}
}

resource vaultName_vaultstorageconfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2020-02-02' = if (changeStorageType) {
  parent: vaultName_resource
  name: 'vaultstorageconfig'
  properties: {
    StorageModelType: vaultStorageType
  }
}
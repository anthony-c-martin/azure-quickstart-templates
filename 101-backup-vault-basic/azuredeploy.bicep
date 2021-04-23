@description('Name of the Vault')
param vaultName string = 'BackupVault'

@allowed([
  'LocallyRedundant'
  'ZonallyRedundant'
  'GeoRedundant'
])
@description('Change Vault Storage Type (not allowed if the vault has registered backups)')
param vaultStorageRedundancy string = 'GeoRedundant'

@description('Location for all resources.')
param location string = resourceGroup().location

resource vaultName_resource 'Microsoft.DataProtection/BackupVaults@2020-01-01-alpha' = {
  name: vaultName
  location: location
  identity: {
    type: 'systemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: vaultStorageRedundancy
      }
    ]
  }
}
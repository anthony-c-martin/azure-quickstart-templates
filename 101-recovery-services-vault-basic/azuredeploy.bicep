@description('Name of the Vault')
param vaultName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2020-02-02-preview' = {
  name: vaultName
  location: location
  properties: {}
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}
param vaultName string {
  metadata: {
    description: 'Name of the Vault'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource vaultName_res 'Microsoft.RecoveryServices/vaults@2020-02-02-preview' = {
  name: vaultName
  location: location
  properties: {}
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}
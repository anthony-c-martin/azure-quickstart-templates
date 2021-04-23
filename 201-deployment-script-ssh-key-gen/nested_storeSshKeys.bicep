@secure()
param keys object
param vaultName string
param secretName string

resource vaultName_secretName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${vaultName}/${secretName}'
  properties: {
    value: keys.privateKey
  }
}
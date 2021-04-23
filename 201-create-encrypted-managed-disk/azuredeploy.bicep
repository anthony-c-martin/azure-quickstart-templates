@description('Storage VHD Uri')
param vhdUri string

@description('Name of the managed disk to be copied')
param managedDiskName string

@description('KeyVault resource id. Ex: /subscriptions/subscriptionid/resourceGroups/contosorg/providers/Microsoft.KeyVault/vaults/contosovault')
param keyVaultResourceID string

@description('KeyVault secret Url. Ex: https://contosovault.vault.azure.net/secrets/contososecret/e088818e865e48488cf363af16dea596')
param keyVaultSecretUrl string

@allowed([
  'nokek'
  'kek'
])
@description('Select kek if the secret is encrypted with a key encryption key and pass explicit keyVaultKekUrl. For nokek, you can keep keyVaultKekUrl empty.')
param useExistingKek string = 'nokek'

@description('key encryption key Url. Ex: https://contosovault.vault.azure.net/keys/contosokek/562a4bb76b524a1493a6afe8e536ee78')
param kekUrl string = ''

@description('key encryption key vault resource id. Ex: /subscriptions/subscriptionid/resourceGroups/contosorg/providers/Microsoft.KeyVault/vaults/contosovault')
param kekVaultResourceID string = ''

var createDiskUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-create-encrypted-managed-disk/CreateEncryptedManagedDisk-${useExistingKek}.json'

module CreateEncryptedManagedDisk '?' /*TODO: replace with correct path to [variables('createDiskUrl')]*/ = {
  name: 'CreateEncryptedManagedDisk'
  params: {
    vhdUri: vhdUri
    managedDiskName: managedDiskName
    keyVaultResourceID: keyVaultResourceID
    keyVaultSecretUrl: keyVaultSecretUrl
    kekUrl: kekUrl
    kekVaultResourceID: kekVaultResourceID
  }
}
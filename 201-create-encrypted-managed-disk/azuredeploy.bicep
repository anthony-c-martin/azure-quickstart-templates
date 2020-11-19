param vhdUri string {
  metadata: {
    description: 'Storage VHD Uri'
  }
}
param managedDiskName string {
  metadata: {
    description: 'Name of the managed disk to be copied'
  }
}
param keyVaultResourceID string {
  metadata: {
    description: 'KeyVault resource id. Ex: /subscriptions/subscriptionid/resourceGroups/contosorg/providers/Microsoft.KeyVault/vaults/contosovault'
  }
}
param keyVaultSecretUrl string {
  metadata: {
    description: 'KeyVault secret Url. Ex: https://contosovault.vault.azure.net/secrets/contososecret/e088818e865e48488cf363af16dea596'
  }
}
param useExistingKek string {
  allowed: [
    'nokek'
    'kek'
  ]
  metadata: {
    description: 'Select kek if the secret is encrypted with a key encryption key and pass explicit keyVaultKekUrl. For nokek, you can keep keyVaultKekUrl empty.'
  }
  default: 'nokek'
}
param kekUrl string {
  metadata: {
    description: 'key encryption key Url. Ex: https://contosovault.vault.azure.net/keys/contosokek/562a4bb76b524a1493a6afe8e536ee78'
  }
  default: ''
}
param kekVaultResourceID string {
  metadata: {
    description: 'key encryption key vault resource id. Ex: /subscriptions/subscriptionid/resourceGroups/contosorg/providers/Microsoft.KeyVault/vaults/contosovault'
  }
  default: ''
}

var createDiskUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-create-encrypted-managed-disk/CreateEncryptedManagedDisk-${useExistingKek}.json'

module CreateEncryptedManagedDisk '<failed to parse [variables(\'createDiskUrl\')]>' = {
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
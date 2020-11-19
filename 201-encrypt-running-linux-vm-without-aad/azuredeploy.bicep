param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param keyVaultName string {
  metadata: {
    description: 'Name of the KeyVault to place the volume encryption key'
  }
}
param keyVaultResourceGroup string {
  metadata: {
    description: 'Resource group of the KeyVault'
  }
}
param keyEncryptionKeyURL string {
  metadata: {
    description: 'URL of the KeyEncryptionKey used to encrypt the volume encryption key'
  }
  default: ''
}
param volumeType string {
  metadata: {
    description: 'Type of the volume OS or Data to perform encryption operation'
  }
  default: 'All'
}
param forceUpdateTag string {
  metadata: {
    description: 'Pass in an unique value like a GUID everytime the operation needs to be force run'
  }
  default: '1.0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '1.1'
var encryptionOperation = 'EnableEncryption'
var keyEncryptionAlgorithm = 'RSA-OAEP'
var keyVaultResourceID = resourceId(keyVaultResourceGroup, 'Microsoft.KeyVault/vaults/', keyVaultName)

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/${extensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    forceUpdateTag: forceUpdateTag
    settings: {
      EncryptionOperation: encryptionOperation
      KeyVaultURL: reference(keyVaultResourceID, '2016-10-01').vaultUri
      KeyVaultResourceId: keyVaultResourceID
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KekVaultResourceId: (empty(keyEncryptionKeyURL) ? '' : keyVaultResourceID)
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      VolumeType: volumeType
    }
  }
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'Name of VMSS to be encrypted'
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
param keyEncryptionAlgorithm string {
  metadata: {
    description: 'keyEncryptionAlgorithm used to wrap volume encryption key using KeyEncryptionKeyURL'
  }
  default: 'RSA-OAEP'
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
  default: uniqueString(resourceGroup().id, deployment().name)
}
param resizeOSDisk bool {
  metadata: {
    description: 'Should the OS partition be resized to occupy full OS VHD before splitting system volume'
  }
  default: false
}

var keyVaultResourceID = resourceId(keyVaultResourceGroup, 'Microsoft.KeyVault/vaults/', keyVaultName)

resource vmssName_AzureDiskEncryption 'Microsoft.Compute/virtualMachineScaleSets/extensions@2017-03-30' = {
  name: '${vmssName}/AzureDiskEncryption'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: forceUpdateTag
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: reference(keyVaultResourceID, '2018-02-14-preview').vaultUri
      KeyVaultResourceId: keyVaultResourceID
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KekVaultResourceId: keyVaultResourceID
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      VolumeType: volumeType
      ResizeOSDisk: resizeOSDisk
    }
  }
}
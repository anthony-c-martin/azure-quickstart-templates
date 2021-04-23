@maxLength(61)
@description('Name of VMSS to be encrypted')
param vmssName string

@description('Name of the KeyVault to place the volume encryption key')
param keyVaultName string

@description('Resource group of the KeyVault')
param keyVaultResourceGroup string

@description('URL of the KeyEncryptionKey used to encrypt the volume encryption key')
param keyEncryptionKeyURL string = ''

@description('keyEncryptionAlgorithm used to wrap volume encryption key using KeyEncryptionKeyURL')
param keyEncryptionAlgorithm string = 'RSA-OAEP'

@description('Type of the volume OS or Data to perform encryption operation')
param volumeType string = 'All'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = uniqueString(resourceGroup().id, deployment().name)

@description('Should the OS partition be resized to occupy full OS VHD before splitting system volume')
param resizeOSDisk bool = false

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
@description('Name of the virtual machine')
param vmName string

@description('Name of the KeyVault to place the volume encryption key')
param keyVaultName string

@description('Resource group of the KeyVault')
param keyVaultResourceGroup string

@description('URL of the KeyEncryptionKey used to encrypt the volume encryption key')
param keyEncryptionKeyURL string = ''

@description('Type of the volume OS or Data to perform encryption operation')
param volumeType string = 'All'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = '1.0'

@description('Should the OS partition be resized to occupy full OS VHD before splitting system volume')
param resizeOSDisk bool = false

@description('Location for all resources.')
param location string = resourceGroup().location

var extensionName = 'AzureDiskEncryption'
var extensionVersion = '2.2'
var encryptionOperation = 'EnableEncryption'
var keyEncryptionAlgorithm = 'RSA-OAEP'
var keyVaultResourceID = resourceId(keyVaultResourceGroup, 'Microsoft.KeyVault/vaults/', keyVaultName)

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
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
      KeyVaultURL: reference(keyVaultResourceID, '2019-09-01').vaultUri
      KeyVaultResourceId: keyVaultResourceID
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KekVaultResourceId: keyVaultResourceID
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      VolumeType: volumeType
      ResizeOSDisk: resizeOSDisk
    }
  }
}
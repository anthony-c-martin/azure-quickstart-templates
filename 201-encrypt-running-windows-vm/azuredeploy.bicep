@description('Name of the virtual machine')
param vmName string

@description('Client ID of AAD app which has permissions to KeyVault')
param aadClientID string

@description('Client Secret of AAD app which has permissions to KeyVault')
@secure()
param aadClientSecret string

@description('Name of the KeyVault to place the volume encryption key')
param keyVaultName string

@description('Resource group of the KeyVault')
param keyVaultResourceGroup string

@allowed([
  'nokek'
  'kek'
])
@description('Select kek if the secret should be encrypted with a key encryption key and pass explicit keyEncryptionKeyURL. For nokek, you can keep keyEncryptionKeyURL empty.')
param useExistingKek string = 'nokek'

@description('URL of the KeyEncryptionKey used to encrypt the volume encryption key')
param keyEncryptionKeyURL string = ''

@description('Type of the volume OS or Data to perform encryption operation')
param volumeType string = 'All'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param sequenceVersion string = '1.0'

@description('Location for all resources.')
param location string = resourceGroup().location

var extensionName = 'AzureDiskEncryption'
var extensionVersion = '1.1'
var encryptionOperation = 'EnableEncryption'
var keyEncryptionAlgorithm = 'RSA-OAEP'
var updateVmUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-encrypt-running-windows-vm/updatevm-${useExistingKek}.json'
var keyVaultURL = 'https://${keyVaultName}.vault.azure.net/'
var keyVaultResourceID = '${subscription().id}/resourceGroups/${keyVaultResourceGroup}/providers/Microsoft.KeyVault/vaults/${keyVaultName}'

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2016-04-30-preview' = {
  name: '${vmName}/${extensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    forceUpdateTag: sequenceVersion
    settings: {
      AADClientID: aadClientID
      KeyVaultURL: keyVaultURL
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      VolumeType: volumeType
      EncryptionOperation: encryptionOperation
    }
    protectedSettings: {
      AADClientSecret: aadClientSecret
    }
  }
}

module updatevm '?' /*TODO: replace with correct path to [variables('updateVmUrl')]*/ = {
  name: 'updatevm'
  params: {
    vmName: vmName
    keyVaultResourceID: keyVaultResourceID
    keyVaultSecretUrl: vmName_extensionName.properties.instanceView.statuses[0].message
    keyEncryptionKeyURL: keyEncryptionKeyURL
  }
}

output BitLockerKey string = vmName_extensionName.properties.instanceView.statuses[0].message
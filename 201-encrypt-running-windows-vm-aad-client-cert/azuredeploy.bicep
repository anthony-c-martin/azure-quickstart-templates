param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param aadClientID string {
  metadata: {
    description: 'Client ID of AAD app which has permissions to KeyVault'
  }
}
param aadClientCertThumbprint string {
  metadata: {
    description: 'Thumbprint of the certificate associated with the AAD app which has permissions to KeyVault'
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
param useExistingKek string {
  allowed: [
    'nokek'
    'kek'
  ]
  metadata: {
    description: 'Select kek if the secret should be encrypted with a key encryption key and pass explicit keyEncryptionKeyURL. For nokek, you can keep keyEncryptionKeyURL empty.'
  }
  default: 'nokek'
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
param sequenceVersion string {
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
      AADClientCertThumbprint: aadClientCertThumbprint
      KeyVaultURL: keyVaultURL
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      VolumeType: volumeType
      EncryptionOperation: encryptionOperation
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
  dependsOn: [
    vmName_extensionName
  ]
}

output BitLockerKey string = vmName_extensionName.properties.instanceView.statuses[0].message
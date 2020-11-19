param aadClientID string {
  metadata: {
    description: 'Client ID of AAD app which has permissions to KeyVault'
  }
}
param aadClientSecret string {
  metadata: {
    description: 'Client Secret of AAD app which has permissions to KeyVault'
  }
  secure: true
}
param diskFormatQuery string {
  metadata: {
    description: 'the query string used to identify the disks to format and encrypt. This parameter only works when you set the EncryptionOperation as EnableEncryptionFormat. For example, passing [{"dev_path":"/dev/md0","name":"encryptedraid","file_system":"ext4"}] will format /dev/md0, encrypt it and mount it at /mnt/dataraid. This parameter should only be used for RAID devices. The specified device must not have any existing filesystem on it.'
  }
  default: ''
}
param encryptionOperation string {
  allowed: [
    'EnableEncryption'
    'EnableEncryptionFormat'
  ]
  metadata: {
    description: 'EnableEncryption would encrypt the disks in place and EnableEncryptionFormat would format the disks directly'
  }
  default: 'EnableEncryption'
}
param volumeType string {
  allowed: [
    'OS'
    'Data'
    'All'
  ]
  metadata: {
    description: 'Defines which drives should be encrypted. OS encryption is supported on RHEL 7.2, CentOS 7.2 & Ubuntu 16.04.'
  }
  default: 'Data'
}
param keyEncryptionKeyURL string {
  metadata: {
    description: 'URL of the KeyEncryptionKey used to encrypt the volume encryption key'
  }
  default: ''
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
param passphrase string {
  metadata: {
    description: 'The passphrase for the disks'
  }
  secure: true
  default: ''
}
param sequenceVersion string {
  metadata: {
    description: 'sequence version of the bitlocker operation. Increment this everytime an operation is performed on the same VM'
  }
  default: '1'
}
param useKek string {
  allowed: [
    'nokek'
    'kek'
  ]
  metadata: {
    description: 'Select kek if the secret should be encrypted with a key encryption key'
  }
  default: 'nokek'
}
param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '0.1'
var keyEncryptionAlgorithm = 'RSA-OAEP'
var updateVmUrl = '${artifactsLocation}/201-encrypt-running-linux-vm/updatevm-${useKek}.json${artifactsLocationSasToken}'
var keyVaultURL = 'https://${keyVaultName}.vault.azure.net/'
var keyVaultResourceID = '${subscription().id}/resourceGroups/${keyVaultResourceGroup}/providers/Microsoft.KeyVault/vaults/${keyVaultName}'

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${extensionName}'
  location: location
  properties: {
    protectedSettings: {
      AADClientSecret: aadClientSecret
      Passphrase: passphrase
    }
    publisher: 'Microsoft.Azure.Security'
    settings: {
      AADClientID: aadClientID
      DiskFormatQuery: diskFormatQuery
      EncryptionOperation: encryptionOperation
      KeyEncryptionAlgorithm: keyEncryptionAlgorithm
      KeyEncryptionKeyURL: keyEncryptionKeyURL
      KeyVaultURL: keyVaultURL
      SequenceVersion: sequenceVersion
      VolumeType: volumeType
    }
    type: 'AzureDiskEncryptionForLinux'
    typeHandlerVersion: extensionVersion
  }
}

module vmName_updateVm '?' /*TODO: replace with correct path to [variables('updateVmUrl')]*/ = {
  name: '${vmName}updateVm'
  params: {
    keyEncryptionKeyURL: keyEncryptionKeyURL
    keyVaultResourceID: keyVaultResourceID
    keyVaultSecretUrl: vmName_extensionName.properties.instanceView.statuses[0].message
    vmName: vmName
  }
  dependsOn: [
    vmName_extensionName
  ]
}

output BitLockerKey string = vmName_extensionName.properties.instanceView.statuses[0].message
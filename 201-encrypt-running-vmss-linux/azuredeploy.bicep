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
    description: 'Volume type being targeted for encryption operation (Data is the only supported type in Linux VMSS Preview)'
  }
  default: 'Data'
}
param forceUpdateTag string {
  metadata: {
    description: 'Pass in a unique value like a GUID everytime the operation needs to be force run'
  }
  default: '1.0'
}

var computeApiVersion = '2017-03-30'
var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '1.1'
var encryptionOperation = 'EnableEncryption'
var keyVaultURL = 'https://${keyVaultName}.vault.azure.net/'
var keyVaultResourceID = '${subscription().id}/resourceGroups/${keyVaultResourceGroup}/providers/Microsoft.KeyVault/vaults/${keyVaultName}'

resource vmssName_res 'Microsoft.Compute/virtualMachineScaleSets@[variables(\'computeApiVersion\')]' = {
  name: vmssName
  location: resourceGroup().location
  sku: {
    name: 'Standard_D2_v2'
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    virtualMachineProfile: {
      extensionProfile: {
        extensions: [
          {
            name: extensionName
            properties: {
              publisher: 'Microsoft.Azure.Security'
              type: extensionName
              typeHandlerVersion: extensionVersion
              autoUpgradeMinorVersion: true
              forceUpdateTag: forceUpdateTag
              settings: {
                EncryptionOperation: encryptionOperation
                KeyVaultURL: keyVaultURL
                KeyVaultResourceId: keyVaultResourceID
                KeyEncryptionKeyURL: keyEncryptionKeyURL
                KekVaultResourceId: (empty(keyEncryptionKeyURL) ? '' : keyVaultResourceID)
                KeyEncryptionAlgorithm: keyEncryptionAlgorithm
                VolumeType: volumeType
              }
            }
          }
        ]
      }
    }
  }
}
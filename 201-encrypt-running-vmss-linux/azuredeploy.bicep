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

@description('Volume type being targeted for encryption operation (Data is the only supported type in Linux VMSS Preview)')
param volumeType string = 'Data'

@description('Pass in a unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = '1.0'

var computeApiVersion = '2017-03-30'
var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '1.1'
var encryptionOperation = 'EnableEncryption'
var keyVaultURL = 'https://${keyVaultName}.vault.azure.net/'
var keyVaultResourceID = '${subscription().id}/resourceGroups/${keyVaultResourceGroup}/providers/Microsoft.KeyVault/vaults/${keyVaultName}'

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@[variables(\'computeApiVersion\')]' = {
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
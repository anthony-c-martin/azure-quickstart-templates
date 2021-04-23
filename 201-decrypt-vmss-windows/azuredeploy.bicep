@maxLength(61)
@description('Name of VMSS to be decrypted')
param vmssName string

@description('Type of the volume OS or Data to perform encryption operation')
param volumeType string = 'All'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = uniqueString(resourceGroup().id, deployment().name)

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
      EncryptionOperation: 'DisableEncryption'
      VolumeType: volumeType
    }
  }
}
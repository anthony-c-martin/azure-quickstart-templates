@description('Name of the virtual machine')
param vmName string

@description('Volume type being decrypted')
param volumeType string = 'Data'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = uniqueString(resourceGroup().id, deployment().name)

@description('Location for all resources.')
param location string = resourceGroup().location

resource vmName_AzureDiskEncryptionForLinux 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/AzureDiskEncryptionForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryptionForLinux'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    forceUpdateTag: forceUpdateTag
    settings: {
      EncryptionOperation: 'DisableEncryption'
      VolumeType: volumeType
    }
  }
}
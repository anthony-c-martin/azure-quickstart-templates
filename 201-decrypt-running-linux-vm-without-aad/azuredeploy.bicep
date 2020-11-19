param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param volumeType string {
  metadata: {
    description: 'Volume type being decrypted'
  }
  default: 'Data'
}
param forceUpdateTag string {
  metadata: {
    description: 'Pass in an unique value like a GUID everytime the operation needs to be force run'
  }
  default: uniqueString(resourceGroup().id, deployment().name)
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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
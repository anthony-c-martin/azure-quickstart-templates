param vmssName string {
  maxLength: 61
  metadata: {
    description: 'Name of VMSS to be decrypted'
  }
}
param volumeType string {
  metadata: {
    description: 'Type of the volume OS or Data to perform encryption operation'
  }
  default: 'All'
}
param forceUpdateTag string {
  metadata: {
    description: 'Pass in an unique value like a GUID everytime the operation needs to be force run'
  }
  default: uniqueString(resourceGroup().id, deployment().name)
}

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
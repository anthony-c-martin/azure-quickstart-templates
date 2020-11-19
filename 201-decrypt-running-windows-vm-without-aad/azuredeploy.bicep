param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource vmName_AzureDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/AzureDiskEncryption'
  location: location
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
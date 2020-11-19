param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param volumeType string {
  allowed: [
    'All'
    'OS'
    'Data'
  ]
  metadata: {
    description: 'Type of the volume OS or Data or All to perform decryption operation'
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
var encryptionOperation = 'DisableEncryption'
var updateEncryptionSettingsUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-decrypt-running-windows-vm/updateEncryptionSettings-${volumeType}.json'

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
      VolumeType: volumeType
      EncryptionOperation: encryptionOperation
    }
  }
}

module updatevm '<failed to parse [variables(\'updateEncryptionSettingsUrl\')]>' = {
  name: 'updatevm'
  params: {
    vmName: vmName
  }
  dependsOn: [
    vmName_extensionName
  ]
}
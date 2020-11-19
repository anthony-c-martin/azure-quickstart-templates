param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param volumeType string {
  allowed: [
    'Data'
  ]
  metadata: {
    description: 'Decryption is supported only on data drives for Linux VMs.'
  }
  default: 'Data'
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

var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '0.1'
var encryptionOperation = 'DisableEncryption'
var updateEncryptionSettingsUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-decrypt-running-linux-vm/updateEncryptionSettings.json'

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  name: '${vmName}/${extensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryptionForLinux'
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    forceUpdateTag: sequenceVersion
    settings: {
      VolumeType: volumeType
      EncryptionOperation: encryptionOperation
      SequenceVersion: sequenceVersion
    }
  }
}

module updatevm '?' /*TODO: replace with correct path to [variables('updateEncryptionSettingsUrl')]*/ = {
  name: 'updatevm'
  params: {
    vmName: vmName
  }
  dependsOn: [
    vmName_extensionName
  ]
}
@description('Name of the virtual machine')
param vmName string

@allowed([
  'All'
  'OS'
  'Data'
])
@description('Type of the volume OS or Data or All to perform decryption operation')
param volumeType string = 'All'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param sequenceVersion string = '1.0'

@description('Location for all resources.')
param location string = resourceGroup().location

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

module updatevm '?' /*TODO: replace with correct path to [variables('updateEncryptionSettingsUrl')]*/ = {
  name: 'updatevm'
  params: {
    vmName: vmName
  }
  dependsOn: [
    vmName_extensionName
  ]
}
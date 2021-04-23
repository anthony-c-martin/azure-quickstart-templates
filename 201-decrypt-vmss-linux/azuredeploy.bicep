@maxLength(61)
@description('Name of VMSS to be decrypted')
param vmssName string

@description('Type of the volume to perform encryption operation (Linux VMSS Preview only supports Data)')
param volumeType string = 'Data'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = '1.0'

var computeApiVersion = '2017-03-30'
var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '1.1'
var encryptionOperation = 'DisableEncryption'

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
                VolumeType: volumeType
                EncryptionOperation: encryptionOperation
              }
            }
          }
        ]
      }
    }
  }
}
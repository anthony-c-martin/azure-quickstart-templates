param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param imagePublisher string {
  metadata: {
    description: 'Publisher of OS image'
  }
  default: 'MicrosoftWindowsServer'
}
param imageOffer string {
  metadata: {
    description: 'OS image offer'
  }
  default: 'WindowsServer'
}
param imageSku string {
  metadata: {
    description: 'OS image SKU'
  }
  default: '2012-R2-Datacenter'
}
param osVersion string {
  metadata: {
    description: 'OS Version. This will pick a fully patched image of this given OS version. Example values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.'
  }
  default: 'latest'
}
param instanceCount int {
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
  default: 2
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password on all VMs.'
  }
  secure: true
}
param keyVaultName string {
  metadata: {
    description: 'Name of the KeyVault to place the volume encryption key'
  }
}
param keyVaultResourceGroup string {
  metadata: {
    description: 'Resource group of the KeyVault'
  }
  default: resourceGroup().name
}
param keyEncryptionKeyURL string {
  metadata: {
    description: 'URL of the KeyEncryptionKey used to encrypt the volume encryption key. The Valut is assumed to be in keyVaultResourceGroup'
  }
}
param keyEncryptionAlgorithm string {
  metadata: {
    description: 'Key encryption algorithm used to wrap with KeyEncryptionKeyURL'
  }
  default: 'RSA-OAEP'
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
  default: '1.0'
}

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var jumpBoxName_var = '${namingInfix}jbox'
var jumpBoxSAName_var = 'jumpboxsa${uniqueString(resourceGroup().id)}'
var jumpBoxOSDiskName = '${jumpBoxName_var}osdisk'
var jumpBoxIPConfigName = '${jumpBoxName_var}ipconfig'
var jumpBoxNicName_var = '${jumpBoxName_var}nic'
var storageAccountType = 'Standard_LRS'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPAddressName_var = '${namingInfix}pip'
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var osType = {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: osVersion
}
var imageReference = osType
var extensionName = 'AzureDiskEncryption'
var extensionVersion = '2.1'
var encryptionOperation = 'EnableEncryption'
var keyVaultResourceId = resourceId(keyVaultResourceGroup, 'Microsoft.KeyVault/vaults', keyVaultName)

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource jumpBoxSAName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: jumpBoxSAName_var
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource jumpBoxNicName 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: jumpBoxNicName_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: jumpBoxIPConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource jumpBoxName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jumpBoxName_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: jumpBoxName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: jumpBoxOSDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpBoxNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(jumpBoxSAName_var).primaryEndpoints.blob
      }
    }
  }
}

resource vmssName_res 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmssName
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: subnetRef
                    }
                  }
                }
              ]
            }
          }
        ]
      }
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
                encryptionOperation: encryptionOperation
                keyVaultURL: reference(keyVaultResourceId, '2016-10-01').vaultUri
                keyVaultResourceId: keyVaultResourceId
                keyEncryptionKeyURL: keyEncryptionKeyURL
                kekVaultResourceId: keyVaultResourceId
                keyEncryptionAlgorithm: keyEncryptionAlgorithm
                volumeType: volumeType
              }
            }
          }
        ]
      }
    }
  }
}
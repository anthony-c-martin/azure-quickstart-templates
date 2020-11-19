param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set (7GB or more RAM suggested for Linux)'
  }
  default: 'Standard_A4_v2'
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
    description: 'Type of the volume to perform encryption operation (Linux VMSS only supports Data)'
  }
  default: 'Data'
}
param forceUpdateTag string {
  metadata: {
    description: 'Pass in an unique value like a GUID everytime the operation needs to be force run'
  }
  default: '1.0'
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var customData = 'I2Nsb3VkLWNvbmZpZw0KcnVuY21kOg0KIyEvYmluL2Jhc2gNCi0gc3VkbyAtaQ0KLSBhcHQtZ2V0IGluc3RhbGwgbHNzY3NpDQotIExVTjNETj0iJChsc3Njc2kgKjowOjA6MSB8IGF3ayAneyBwcmludCAkTkYgfScpIg0KLSBta2ZzLmV4dDQgJExVTjNETg0KLSBVVUlEMT0iJChibGtpZCAtcyBVVUlEIC1vIHZhbHVlICRMVU4zRE4pIg0KLSBlY2hvICJVVUlEPSRVVUlEMSAvZGF0YTEgZXh0NCBkZWZhdWx0cyxub2ZhaWwgMCAwIiA+Pi9ldGMvZnN0YWINCi0gbWtkaXIgL2RhdGExDQotIG1vdW50IC1hDQoNCmZpbmFsX21lc3NhZ2U6ICJjbG91ZC1jb25maWcgaXMgY29tcGxldGUgYWZ0ZXIgJFVQVElNRSBzZWNvbmRzIg=='
var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var jumpBoxName = '${namingInfix}jbox'
var jumpBoxSAName = 'jumpboxsa${uniqueString(resourceGroup().id)}'
var jumpBoxIPConfigName = '${jumpBoxName}ipconfig'
var jumpBoxNicName = '${jumpBoxName}nic'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnetName)
var publicIPAddressName = '${namingInfix}pip'
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04-DAILY-LTS'
  version: 'latest'
}
var imageReference = osType
var extensionName = 'AzureDiskEncryptionForLinux'
var extensionVersion = '1.1'
var encryptionOperation = 'EnableEncryption'
var keyVaultResourceId = resourceId(keyVaultResourceGroup, 'Microsoft.KeyVault/vaults', keyVaultName)
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName
  location: location
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

resource jumpBoxSAName_resource 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: jumpBoxSAName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource jumpBoxNicName_resource 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: jumpBoxNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: jumpBoxIPConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource jumpBoxName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jumpBoxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: jumpBoxName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpBoxNicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(jumpBoxSAName).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    jumpBoxSAName_resource
    jumpBoxNicName_resource
  ]
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmssName
  location: location
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
        imageReference: imageReference
        osDisk: {
          createOption: 'FromImage'
        }
        copy: [
          {
            name: 'dataDisks'
            count: 4
            input: {
              lun: copyIndex('dataDisks')
              diskSizeGB: 10
              createOption: 'Empty'
              caching: 'None'
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        customData: customData
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
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
                      id: subnetId
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
                EncryptionOperation: encryptionOperation
                KeyVaultURL: reference(keyVaultResourceId, '2016-10-01').vaultUri
                KeyVaultResourceId: keyVaultResourceId
                KekVaultResourceId: keyVaultResourceId
                KeyEncryptionKeyURL: keyEncryptionKeyURL
                KeyEncryptionAlgorithm: keyEncryptionAlgorithm
                VolumeType: volumeType
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}
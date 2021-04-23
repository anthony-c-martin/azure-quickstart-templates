@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string

@description('Size of VMs in the VM Scale Set (7GB or more RAM suggested for Linux)')
param vmSku string = 'Standard_A4_v2'

@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@description('Name of the KeyVault to place the volume encryption key')
param keyVaultName string

@description('Resource group of the KeyVault')
param keyVaultResourceGroup string = resourceGroup().name

@description('URL of the KeyEncryptionKey used to encrypt the volume encryption key. The Valut is assumed to be in keyVaultResourceGroup')
param keyEncryptionKeyURL string

@description('Key encryption algorithm used to wrap with KeyEncryptionKeyURL')
param keyEncryptionAlgorithm string = 'RSA-OAEP'

@description('Type of the volume to perform encryption operation (Linux VMSS only supports Data)')
param volumeType string = 'Data'

@description('Pass in an unique value like a GUID everytime the operation needs to be force run')
param forceUpdateTag string = '1.0'

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Location for all resources.')
param location string = resourceGroup().location

var customData = 'I2Nsb3VkLWNvbmZpZw0KcnVuY21kOg0KIyEvYmluL2Jhc2gNCi0gc3VkbyAtaQ0KLSBhcHQtZ2V0IGluc3RhbGwgbHNzY3NpDQotIExVTjNETj0iJChsc3Njc2kgKjowOjA6MSB8IGF3ayAneyBwcmludCAkTkYgfScpIg0KLSBta2ZzLmV4dDQgJExVTjNETg0KLSBVVUlEMT0iJChibGtpZCAtcyBVVUlEIC1vIHZhbHVlICRMVU4zRE4pIg0KLSBlY2hvICJVVUlEPSRVVUlEMSAvZGF0YTEgZXh0NCBkZWZhdWx0cyxub2ZhaWwgMCAwIiA+Pi9ldGMvZnN0YWINCi0gbWtkaXIgL2RhdGExDQotIG1vdW50IC1hDQoNCmZpbmFsX21lc3NhZ2U6ICJjbG91ZC1jb25maWcgaXMgY29tcGxldGUgYWZ0ZXIgJFVQVElNRSBzZWNvbmRzIg=='
var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var jumpBoxName_var = '${namingInfix}jbox'
var jumpBoxSAName_var = 'jumpboxsa${uniqueString(resourceGroup().id)}'
var jumpBoxIPConfigName = '${jumpBoxName_var}ipconfig'
var jumpBoxNicName_var = '${jumpBoxName_var}nic'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnetName)
var publicIPAddressName_var = '${namingInfix}pip'
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName_var
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

resource jumpBoxSAName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: jumpBoxSAName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource jumpBoxNicName 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: jumpBoxNicName_var
  location: location
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
            id: subnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource jumpBoxName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jumpBoxName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: jumpBoxName_var
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
  dependsOn: [
    jumpBoxSAName
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
        dataDisks: [for j in range(0, 4): {
          lun: j
          diskSizeGB: 10
          createOption: 'Empty'
          caching: 'None'
        }]
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
    virtualNetworkName
  ]
}
@minLength(3)
@maxLength(15)
@description('Name of the Windows VM that will perform the copy of the VHD from a source storage account to the new storage account created in the new deployment, this is known as transfer vm.')
param transferVmName string = 'TransferVM'

@description('VM size of new virtual machine that will be deployed from a custom image.')
param vmSize string = 'Standard_D1'

@minLength(3)
@maxLength(15)
@description('Name of the new VM deployed from the custom image.')
param newVmName string = 'NewVM'

@minLength(1)
@description('Name of the local administrator account, this cannot be Admin, Administrator or root.')
param adminUsername string

@minLength(8)
@description('Local administrator password, complex password is required, do not use any variation of the password word because it will be rejected.')
@secure()
param adminPassword string

@description('Resource group name of the source storage account.')
param sourceStorageAccountResourceGroup string

@description('Full URIs for one or more custom images (VHDs) that should be copied to the deployment storage account to spin up new VMs from them. URLs must be comma separated.')
param sourceImageURI string

@description('Name of the VHD to be used as source syspreped/generalized image to deploy the VM. E.g. mybaseimage.vhd.')
param customImageName string = last(split(sourceImageURI, '/'))

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-custom-image-new-storage-account/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var sourceStorageAccountName = substring(split(sourceImageURI, '.')[0], 8)
var vmCount = 2
var vmNames = [
  transferVmName
  newVmName
]
var nicNames_var = [
  '${transferVmName}Nic'
  '${newVmName}Nic'
]
var storageAccountType = 'Standard_LRS'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}sa'
var virtualNetworkName_var = 'vNet'
var vnetSubnetName1 = 'LabSubnet'
var SubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, vnetSubnetName1)
var publicIpNames_var = [
  '${transferVmName}PublicIP'
  '${newVmName}PublicIP'
]
var windowsOSVersion = '2016-Datacenter'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var transferVmSize = 'Standard_D1'
var vhdStorageAccountContainerName = 'vhds'

resource StorageAccountName 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  name: storageAccountName_var
  location: location
  tags: {
    displayName: 'StorageAccount'
  }
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
  dependsOn: []
}

resource VirtualNetworkName 'Microsoft.Network/virtualNetworks@2017-11-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'vnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: vnetSubnetName1
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource publicIpNames 'Microsoft.Network/publicIPAddresses@2017-11-01' = [for i in range(0, vmCount): {
  name: publicIpNames_var[i]
  location: location
  tags: {
    displayName: '${publicIpNames_var[i]} Public IP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: []
}]

resource nicNames 'Microsoft.Network/networkInterfaces@2017-11-01' = [for i in range(0, vmCount): {
  name: nicNames_var[i]
  location: location
  tags: {
    displayName: '${vmNames[i]} Network Interface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: SubnetRef
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIpNames_var[i])
          }
        }
      }
    ]
  }
  dependsOn: [
    VirtualNetworkName
    publicIpNames
  ]
}]

resource vmNames_0 'Microsoft.Compute/virtualMachines@2017-12-01' = {
  name: vmNames[0]
  location: location
  tags: {
    displayName: vmNames[0]
  }
  properties: {
    hardwareProfile: {
      vmSize: transferVmSize
    }
    osProfile: {
      computerName: vmNames[0]
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmNames[0]}-osdisk'
        vhd: {
          uri: '${reference(storageAccountName_var).primaryEndpoints.blob}${vhdStorageAccountContainerName}/${vmNames[0]}-osdisk.vhd'
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicNames_var[0]))
        }
      ]
    }
  }
  dependsOn: [
    StorageAccountName
    nicNames
  ]
}

resource vmNames_0_VMNames_0_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  name: '${vmNames[0]}/${vmNames[0]}CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    autoUpgradeMinorVersion: true
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        '${artifactsLocation}/ImageTransfer.ps1${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ImageTransfer.ps1 -SourceImage ${sourceImageURI} -SourceSAKey ${listKeys(resourceId(sourceStorageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', sourceStorageAccountName), '2017-10-01').keys[0].value} -DestinationURI ${reference(storageAccountName_var).primaryEndpoints.blob}${vhdStorageAccountContainerName} -DestinationSAKey ${listKeys('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2017-10-01').keys[0].value}'
    }
  }
  dependsOn: [
    vmNames_0
  ]
}

resource vmNames_1 'Microsoft.Compute/virtualMachines@2017-12-01' = {
  name: vmNames[1]
  location: location
  tags: {
    displayName: vmNames[1]
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNames[1]
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        name: '${vmNames[1]}-osdisk'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        image: {
          uri: '${reference(storageAccountName_var).primaryEndpoints.blob}${vhdStorageAccountContainerName}/${customImageName}'
        }
        vhd: {
          uri: '${reference(storageAccountName_var).primaryEndpoints.blob}${vhdStorageAccountContainerName}/${vmNames[1]}-osdisk.vhd'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicNames_var[1]))
        }
      ]
    }
  }
  dependsOn: [
    StorageAccountName
    nicNames
    '${vmNames[0]}CustomScriptExtension'
  ]
}
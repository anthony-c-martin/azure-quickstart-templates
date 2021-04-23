@description('Number of VMs to deploy')
param scaleNumber int = 2

@description('Name of new storage account')
param newStorageAccountName string

@description('Type of storage account')
param storageAccountType string = 'Standard_LRS'

@description('Name of the VM')
param vmName string

@description('Size of the VM')
param vmSize string = 'Standard_D1'

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@description('Image SKU')
param imageSKU string = '14.04.2-LTS'

@description('VM Admin Username')
param adminUsername string

@description('Path to the download the custom script from')
param customScriptFilePath string

@description('Command to execute on the VM')
param customScriptCommandToExecute string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var availabilitySetName_var = 'myAVSet'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = 'myVNET'
var vnetID = virtualNetworkName.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var nicName = 'myNic'
var vmExtensionName = 'myCustomScriptExtension'
var networkSecurityGroupName_var = 'default-NSG'
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

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: availabilitySetName_var
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
    managed: 'true'
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = [for i in range(0, scaleNumber): {
  name: 'publicIP${i}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName_0 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: concat(nicName, 0)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'publicIP0')
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/publicIP0'
  ]
}

resource nicName_1 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: concat(nicName, 1)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'publicIP1')
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/publicIP1'
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, scaleNumber): {
  name: concat(vmName, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    'Microsoft.Network/networkInterfaces/${nicName}${i}'
    availabilitySetName
  ]
}]

resource vmName_1_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}1/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptFilePath
      ]
      commandToExecute: concat(customScriptCommandToExecute, reference('${nicName}0').ipConfigurations[0].properties.privateIPAddress)
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName}1'
    'Microsoft.Network/networkInterfaces/${nicName}0'
  ]
}
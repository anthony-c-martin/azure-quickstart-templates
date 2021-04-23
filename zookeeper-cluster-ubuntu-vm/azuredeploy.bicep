@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('Storage Account type')
param diskType string = 'Standard_LRS'

@description('VM name')
param vmName string

@description('Size of the VM')
param vmSize string = 'Standard_D2_v2'

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@description('Image SKU')
param imageSKU string = '18.04-LTS'

@description('Admin username')
param adminUsername string

@description('Number of Zookeeper nodes to provision')
param scaleNumber int = 3

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

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/zookeeper-cluster-ubuntu-vm/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var availabilitySetName_var = 'zookeeperAvSet'
var virtualNetworkName_var = 'zookeeperVNET'
var vnetAddressPrefix = '10.0.0.0/16'
var publicIPAddressType = 'Dynamic'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var nicName_var = 'zookeeperNIC'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
var customScriptFilePath = uri(artifactsLocation, 'zookeeper.sh${artifactsLocationSasToken}')
var customScriptCommandToExecute = 'sh zookeeper.sh'
var vmExtensionName = 'zookeeperExtension'
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

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: availabilitySetName_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, scaleNumber): {
  name: 'publicIP${i}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, scaleNumber): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.${(i + 4)}'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'publicIP${i}')
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses/', 'publicIP${i}')
    virtualNetworkName
  ]
}]

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, scaleNumber): {
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
        name: '${vmName}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', concat(nicName_var, i))
    availabilitySetName
  ]
}]

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, scaleNumber): {
  name: '${vmName}${i}/${vmExtensionName}'
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
      commandToExecute: '${customScriptCommandToExecute} ${i} ${scaleNumber}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines/', concat(vmName, i))
  ]
}]
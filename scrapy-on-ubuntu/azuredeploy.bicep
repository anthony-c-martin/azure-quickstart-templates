@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed')
param newStorageAccountName string

@description('This is the dns name of the public IP')
param dnsNameForPublicIP string

@description('Username for the Virtual Machines')
param adminUsername string

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@description('Image SKU')
param imageSKU string = '14.04.5-LTS'

@description('Size of the Virtual Machine')
param vmSize string = 'Standard_A0'

@description('Name of Public IP Address Name')
param publicIPAddressName string

@description('Name of Virtual Machine')
param vmName string

@description('Name of Virtual Network')
param virtualNetworkName string

@description('Name of Network Interface')
param nicName string

@description('Name of the spider')
param spiderName string = 'myspider.py'

@description('Uri of the spider source')
param spiderUri string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/scrapy-on-ubuntu/myspider.py'

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var storageAccountType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vmStorageAccountContainerName = 'vhds'
var OSDiskName = 'osdiskforscrapy'
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
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
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
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
  ]
}

resource vmName_installscrapy 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName_resource
  name: 'installscrapy'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/scrapy-on-ubuntu/scrapy-install-ubuntu.sh'
        spiderUri
      ]
      commandToExecute: 'sh scrapy-install-ubuntu.sh ${spiderName}'
    }
  }
}
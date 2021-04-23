@description('This is the name of the your storage account')
param newStorageAccountName string

@description('This is the unique DNS name of the for the public IP for your VM')
param dnsNameForPublicIP string

@description('This is the username you wish to assign to your VMs admin account')
param adminUsername string

@description('Size of VM')
param vmSize string

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

var addressPrefix = '10.0.0.0/16'
var imagePublisher = 'Canonical'
var imageVersion = 'latest'
var imageSKU = '12.04.5-LTS'
var imageOffer = 'UbuntuServer'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var publicIPAddressName_var = 'myPublicIP'
var storageAccountType = 'Standard_LRS'
var vmName_var = 'myVM'
var virtualNetworkName_var = 'myVNET'
var nicName_var = 'myVMNic'
var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var installMongoTemplateurl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-dependency-between-scripts-using-extensions/install-mongo.json'
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
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
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
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
  ]
}

resource vmName_configuremongo 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName
  name: 'configuremongo'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-dependency-between-scripts-using-extensions/mongo-configure-ubuntu.sh'
      ]
      commandToExecute: 'sh mongo-configure-ubuntu.sh'
    }
  }
}

module installmongo '?' /*TODO: replace with correct path to [variables('installMongoTemplateurl')]*/ = {
  name: 'installmongo'
  params: {
    vmName: vmName_var
  }
  dependsOn: [
    vmName_configuremongo
  ]
}
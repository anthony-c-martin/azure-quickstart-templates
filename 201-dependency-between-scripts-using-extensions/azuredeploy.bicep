param newStorageAccountName string {
  metadata: {
    description: 'This is the name of the your storage account'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'This is the unique DNS name of the for the public IP for your VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'This is the username you wish to assign to your VMs admin account'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of VM'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
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

var addressPrefix = '10.0.0.0/16'
var imagePublisher = 'Canonical'
var imageVersion = 'latest'
var imageSKU = '12.04.5-LTS'
var imageOffer = 'UbuntuServer'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var publicIPAddressName = 'myPublicIP'
var storageAccountType = 'Standard_LRS'
var vmName = 'myVM'
var virtualNetworkName = 'myVNET'
var nicName = 'myVMNic'
var vnetID = virtualNetworkName_resource.id
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: location
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
            id: subnet1Ref
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName
  location: location
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
        version: imageVersion
      }
      osDisk: {
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_configuremongo 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/configuremongo'
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
  dependsOn: [
    vmName_resource
  ]
}

module installmongo '<failed to parse [variables(\'installMongoTemplateurl\')]>' = {
  name: 'installmongo'
  params: {
    vmName: vmName
  }
  dependsOn: [
    vmName_configuremongo
  ]
}
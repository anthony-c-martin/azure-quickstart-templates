param vstsAccountURL string {
  metadata: {
    description: 'Team Services Account URL (e.g. https://myaccount.visualstudio.com)'
  }
}
param vstsPAT string {
  metadata: {
    description: 'Team Services PAT for user with build permissions'
  }
}
param vstsPoolName string {
  metadata: {
    description: 'Team Services Agent Pool Name'
  }
  default: 'default'
}
param vstsAgentName string {
  metadata: {
    description: 'Team Services Agent Name'
  }
  default: 'ubuntu-build-full'
}
param adminUsername string {
  metadata: {
    description: 'Linux VM User Account Name'
  }
  default: 'vstsbuild'
}
param adminPassword string {
  metadata: {
    description: 'Administrator Password'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var imagePublisher = 'canonical'
var imageOffer = 'ubuntuserver'
var imageSKU = '16.04.0-LTS'
var baseName = uniqueString(dnsLabelPrefix, resourceGroup().id, uniqueString(deployment().name))
var nicName_var = 'myNic1${baseName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myIP1${baseName}'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = dnsLabelPrefix
var vmSize = 'Standard_F1'
var virtualNetworkName_var = 'MyVNET'
var vnetID = virtualNetworkName.id
var storageAccountType = 'Standard_LRS'
var storageAccountName_var = 'vsts1${baseName}'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'

resource StorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
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

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
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
  }
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName_var}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vsts-fullbuild-ubuntu-vm/scripts/full-vstsbuild-install.sh'
      ]
      commandToExecute: 'sh full-vstsbuild-install.sh ${vstsAccountURL} ${vstsPAT} ${vstsPoolName} ${vstsAgentName} ${adminUsername}'
    }
  }
}
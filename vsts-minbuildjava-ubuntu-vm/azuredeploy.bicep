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
  default: 'ubuntu-build-minJava'
}
param adminUsername string {
  metadata: {
    description: 'Linux VM User Account Name'
  }
  default: 'vstsbuild'
}
param adminPassword string {
  metadata: {
    description: 'Admin Password'
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
var nicName = 'myNic2${baseName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName = 'myIP2${baseName}'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = dnsLabelPrefix
var vmSize = 'Standard_A0'
var virtualNetworkName = 'MyVNET'
var vnetID = virtualNetworkName_resource.id
var storageAccountType = 'Standard_LRS'
var storageAccountName = 'vsts2${baseName}'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'

resource StorageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
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
    StorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vsts-minbuildjava-ubuntu-vm/scripts/java-vstsbuild-install.sh'
      ]
      commandToExecute: 'sh java-vstsbuild-install.sh ${vstsAccountURL} ${vstsPAT} ${vstsPoolName} ${vstsAgentName} ${adminUsername}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}
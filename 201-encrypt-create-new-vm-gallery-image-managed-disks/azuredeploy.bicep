param vmName string {
  metadata: {
    description: 'Name of the virtual machine'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin user name for the virtual machine'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin user password for virtual machine'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'Size of VM'
  }
  default: 'Standard_D2'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of VNET to which the VM NIC belongs to'
  }
}
param subnetName string {
  metadata: {
    description: 'Name of Subnet to which the VM NIC belongs to'
  }
}
param aadClientID string {
  metadata: {
    description: 'Client ID of AAD app which has permissions to KeyVault'
  }
}
param aadClientSecret string {
  metadata: {
    description: 'Client Secret of AAD app which has permissions to KeyVault'
  }
  secure: true
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
}
param useExistingKek string {
  allowed: [
    'nokek'
    'kek'
  ]
  metadata: {
    description: 'Select kek if the secret should be encrypted with a key encryption key and pass explicit keyEncryptionKeyURL. For nokek, you can keep keyEncryptionKeyURL empty.'
  }
  default: 'nokek'
}
param keyEncryptionKeyURL string {
  metadata: {
    description: 'URL of the KeyEncryptionKey used to encrypt the volume encryption key'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var osSku = '2012-R2-Datacenter'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var dnsNameForPublicIP = toLower(vmName)
var publicIPAddressName = toLower('publicIP${vmName}')
var publicIPAddressType = 'Dynamic'
var nicName = toLower('nic${vmName}')

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
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
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: osSku
        version: 'latest'
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
  }
  dependsOn: [
    nicName_resource
  ]
}

module UpdateEncryptionSettings '<failed to parse https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-encrypt-running-windows-vm/azuredeploy.json>' = {
  name: 'UpdateEncryptionSettings'
  params: {
    vmName: vmName
    aadClientID: aadClientID
    aadClientSecret: aadClientSecret
    keyVaultName: keyVaultName
    keyVaultResourceGroup: keyVaultResourceGroup
    useExistingKek: useExistingKek
    keyEncryptionKeyURL: keyEncryptionKeyURL
  }
  dependsOn: [
    vmName_resource
  ]
}
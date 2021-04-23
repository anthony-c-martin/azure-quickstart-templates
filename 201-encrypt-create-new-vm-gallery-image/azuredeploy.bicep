@description('Name of the virtual machine')
param vmName string

@description('Admin user name for the virtual machine')
param adminUsername string

@description('Admin user password for virtual machine')
@secure()
param adminPassword string

@description('Storage account to store os vhd')
param newStorageAccountName string

@description('Name of the storage account container to store os vhd')
param vmStorageContainerName string = 'vhds'

@description('Size of VM')
param vmSize string = 'Standard_D2'

@description('Name of VNET to which the VM NIC belongs to')
param virtualNetworkName string

@description('Name of Subnet to which the VM NIC belongs to')
param subnetName string

@description('Client ID of AAD app which has permissions to KeyVault')
param aadClientID string

@description('Client Secret of AAD app which has permissions to KeyVault')
@secure()
param aadClientSecret string

@description('Name of the KeyVault to place the volume encryption key')
param keyVaultName string

@description('Resource group of the KeyVault')
param keyVaultResourceGroup string

@allowed([
  'nokek'
  'kek'
])
@description('Select kek if the secret should be encrypted with a key encryption key and pass explicit keyEncryptionKeyURL. For nokek, you can keep keyEncryptionKeyURL empty.')
param useExistingKek string = 'nokek'

@description('URL of the KeyEncryptionKey used to encrypt the volume encryption key')
param keyEncryptionKeyURL string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var osSku = '2012-R2-Datacenter'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var dnsNameForPublicIP = toLower(vmName)
var publicIPAddressName_var = toLower('publicIP${vmName}')
var publicIPAddressType = 'Dynamic'
var nicName_var = toLower('nic${vmName}')

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: subnetRef
          }
        }
      }
    ]
  }
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
          id: nicName.id
        }
      ]
    }
  }
}

module UpdateEncryptionSettings '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-encrypt-running-windows-vm/azuredeploy.json*/ = {
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
@description('Location for all resources')
param location string = resourceGroup().location

@description('The username of the initial account to be created')
param adminUsername string

@description('The password of the initial account to be created')
@secure()
param adminPassword string

@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4095
])
@description('The size of the datadisks to be striped. The total capacity will be this size multiplied by the number of data disks you specify.')
param sizeOfEachDataDiskInGB int = 1024

@allowed([
  8
  16
  32
])
@description('The number of data disks to include in the storage pool.')
param numberOfDisks int = 32

@description('DNS name for the Public IP')
param dnsName string = 'vm-data-disks-${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D64s_v3'
])
@description('VM Size, the list of sizes here all support premium and standard storage up to 32 data disks.')
param vmSize string = 'Standard_D16s_v3'

@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('Storage SKU type')
param storageType string = 'Premium_LRS'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-vm-32-data-disks-high-iops/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var vmName_var = 'vm-high-iops'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2016-Datacenter'
var virtualNetworkName_var = 'highIopsVNET'
var nicName_var = 'highIopsNIC'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName_var = 'highIopsPubIP'
var publicIPAddressType = 'Dynamic'
var configurationFunction = 'StoragePool.ps1\\StoragePool'
var modulesUrl = uri(artifactsLocation, 'DSC/StoragePool.zip')
var DscExtensionName = 'DscExtension'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
var networkSecurityGroupName_var = 'default-NSG'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-04-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-04-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2018-04-01' = {
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
  dependsOn: [
    virtualNetworkName
  ]
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageType
        }
      }
      dataDisks: [for j in range(0, numberOfDisks): {
        diskSizeGB: sizeOfEachDataDiskInGB
        lun: j
        name: '${vmName_var}_DataDisk${j}'
        createOption: 'Empty'
        managedDisk: {
          storageAccountType: storageType
        }
      }]
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

resource vmName_DscExtensionName 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  parent: vmName
  name: '${DscExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: modulesUrl
      SasToken: artifactsLocationSasToken
      ConfigurationFunction: configurationFunction
      Properties: {
        MachineName: vmName_var
      }
    }
    protectedSettings: null
  }
}

output fqdn string = reference(publicIPAddressName_var).dnsSettings.fqdn
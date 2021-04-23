@description('Specify the locations for all resources.')
param location string = resourceGroup().location

@description('Specify the virtual machine admin user name.')
param adminUsername string

@description('Specify the virtual machine admin password.')
@secure()
param adminPassword string

@description('Specify the DNS label for the virtual machine public IP address. It must be lowercase. It should match the following regular expression, or it will raise an error: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param domainNameLabel string

@description('Specify the size of the VM.')
param vmSize string = 'Standard_D2_v3'

@description('Specify the storage account name.')
param storageAccountName string

@description('Name of the resource group for the app config store.')
param appConfigStoreResourceGroup string

@description('App configuration store name.')
param appConfigStoreName string

@description('Specify the name of the key in the app config store for the VM windows sku.')
param vmSkuKey string

@description('Specify the name of the key in the app config store for the VM disk size')
param diskSizeKey string

var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myPublicIP'
var vmName_var = 'SimpleWinVM'
var virtualNetworkName_var = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var appConfigRef = resourceId(appConfigStoreResourceGroup, 'Microsoft.AppConfiguration/configurationStores', appConfigStoreName)
var windowsOSVersionParameters = {
  key: vmSkuKey
  label: 'template'
}
var diskSizeGBParameters = {
  key: diskSizeKey
  label: 'template'
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
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
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: listKeyValue(appConfigRef, '2019-10-01', windowsOSVersionParameters).value
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: listKeyValue(appConfigRef, '2019-10-01', diskSizeGBParameters).value
          lun: 0
          createOption: 'Empty'
        }
      ]
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
        storageUri: storageAccountName_resource.properties.primaryEndpoints.blob
      }
    }
  }
}

output hostname string = reference(publicIPAddressName_var).dnsSettings.fqdn
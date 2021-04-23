@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = 'vm-${uniqueString(resourceGroup().id)}'

@allowed([
  '2008-R2-SP1'
  '2008-R2-SP1-smalldisk'
  '2008-R2-SP1-zhcn'
  '2012-Datacenter'
  '2012-datacenter-gensecond'
  '2012-Datacenter-smalldisk'
  '2012-Datacenter-zhcn'
  '2012-R2-Datacenter'
  '2012-r2-datacenter-gensecond'
  '2012-R2-Datacenter-smalldisk'
  '2012-R2-Datacenter-zhcn'
  '2016-Datacenter'
  '2016-datacenter-gensecond'
  '2016-Datacenter-Server-Core'
  '2016-Datacenter-Server-Core-smalldisk'
  '2016-Datacenter-smalldisk'
  '2016-Datacenter-with-Containers'
  '2016-Datacenter-with-RDSH'
  '2016-Datacenter-zhcn'
  '2019-Datacenter'
  '2019-Datacenter-Core'
  '2019-Datacenter-Core-smalldisk'
  '2019-Datacenter-Core-with-Containers'
  '2019-Datacenter-Core-with-Containers-smalldisk'
  '2019-datacenter-gensecond'
  '2019-Datacenter-smalldisk'
  '2019-Datacenter-with-Containers'
  '2019-Datacenter-with-Containers-smalldisk'
  '2019-Datacenter-zhcn'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.')
param windowsOSVersion string = '2019-Datacenter'

@description('VM Size, note the VM Size determnines the max number of disks available, use \'az vm list-sizes\' or \'Get-AzVmSize\' for details.')
param vmSize string = 'Standard_D2_v3'

@minValue(1)
@maxValue(10)
@description('The number of VMs to create.')
param numberOfVms int = 2

@minValue(1)
@maxValue(64)
@description('This parameter allows the user to select the number of disks they want')
param numDataDisks int = 4

@minValue(16)
@maxValue(4096)
@description('Size of the data disks')
param sizeOfDataDisksInGB int = 100

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = 'diags${uniqueString(resourceGroup().id)}'
var nicName_var = 'dynamicDisksVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'dynamicDisksPublicIP'
var vmName_var = 'dynamicDisksVM'
var virtualNetworkName_var = 'dynamicDisksVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-06-01' = [for i in range(0, numberOfVms): {
  name: concat(publicIPAddressName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: concat(dnsLabelPrefix, i)
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-06-01' = [for i in range(0, numberOfVms): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, i))
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName
    virtualNetworkName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2019-03-01' = [for i in range(0, numberOfVms): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [for j in range(0, numDataDisks): {
        caching: 'ReadWrite'
        diskSizeGB: sizeOfDataDisksInGB
        lun: j
        name: '${vmName_var}-datadisk${i}${j}'
        createOption: 'Empty'
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName
    nicName
  ]
}]
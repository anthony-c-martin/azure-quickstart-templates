param virtualMachineName string {
  metadata: {
    description: 'The name of the VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'The admin user name of the VM'
  }
}
param adminPassword string {
  metadata: {
    description: 'The admin password of the VM'
  }
  secure: true
}
param diskType string {
  allowed: [
    'StandardSSD_LRS'
    'Standard_LRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'The Storage type of the data Disks'
  }
  default: 'StandardSSD_LRS'
}
param virtualMachineSize string {
  metadata: {
    description: 'The virtual machine size. Enter a Premium capable VM size if DiskType is entered as Premium_LRS'
  }
  default: 'Standard_DS3_V2'
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Datacenter'
    '2019-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM.'
  }
  default: '2019-Datacenter'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var dataDiskSize = 1024
var dataDisksCount = 5
var virtualNetworkName_var = '${toLower(virtualMachineName)}-vnet'
var subnetName = '${toLower(virtualMachineName)}-subnet'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var OSDiskName = '${toLower(virtualMachineName)}OSDisk'
var addressPrefix = '10.2.3.0/24'
var subnetPrefix = '10.2.3.0/24'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var networkInterfaceName_var = toLower(virtualMachineName)
var publicIpAddressName_var = '${toLower(virtualMachineName)}-ip'
var networkSecurityGroupName_var = '${subnetName}-nsg'

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIPAddressType
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
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

resource virtualMachineName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        osType: 'Windows'
        name: OSDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
        diskSizeGB: 128
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      copy: [
        {
          name: 'dataDisks'
          count: dataDisksCount
          input: {
            name: '${virtualMachineName}DataDisk${copyIndex('dataDisks')}'
            diskSizeGB: dataDiskSize
            lun: copyIndex('dataDisks')
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: diskType
            }
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}
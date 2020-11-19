param virtualMachineName string {
  metadata: {
    description: 'The name of the VM'
  }
  default: 'myVM'
}
param virtualMachineSize string {
  metadata: {
    description: 'The virtual machine size.'
  }
  default: 'Standard_DS13_v2'
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Specify the name of an existing VNet in the same resource group'
  }
}
param existingVnetResourceGroup string {
  metadata: {
    description: 'Specify the resrouce group of the existing VNet'
  }
  default: resourceGroup().name
}
param existingSubnetName string {
  metadata: {
    description: 'Specify the name of the Subnet Name'
  }
}
param imageOffer string {
  allowed: [
    'sql2019-ws2019'
    'sql2017-ws2019'
    'SQL2017-WS2016'
    'SQL2016SP1-WS2016'
    'SQL2016SP2-WS2016'
    'SQL2014SP3-WS2012R2'
    'SQL2014SP2-WS2012R2'
  ]
  metadata: {
    description: 'Windows Server and SQL Offer'
  }
  default: 'sql2019-ws2019'
}
param sqlSku string {
  allowed: [
    'Standard'
    'Enterprise'
    'SQLDEV'
    'Web'
    'Express'
  ]
  metadata: {
    description: 'SQL Server Sku'
  }
  default: 'Standard'
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
param storageWorkloadType string {
  allowed: [
    'General'
    'OLTP'
    'DW'
  ]
  metadata: {
    description: 'SQL Server Workload Type'
  }
  default: 'General'
}
param sqlDataDisksCount int {
  minValue: 1
  maxValue: 8
  metadata: {
    description: 'Amount of data disks (1TB each) for SQL Data files'
  }
  default: 1
}
param dataPath string {
  metadata: {
    description: 'Path for SQL Data files. Please choose drive letter from F to Z, and other drives from A to E are reserved for system'
  }
  default: 'F:\\SQLData'
}
param sqlLogDisksCount int {
  minValue: 1
  maxValue: 8
  metadata: {
    description: 'Amount of data disks (1TB each) for SQL Log files'
  }
  default: 1
}
param logPath string {
  metadata: {
    description: 'Path for SQL Log files. Please choose drive letter from F to Z and different than the one used for SQL data. Drive letter from A to E are reserved for system'
  }
  default: 'G:\\SQLLog'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var networkInterfaceName = '${virtualMachineName}-nic'
var networkSecurityGroupName = '${virtualMachineName}-nsg'
var networkSecurityGroupRules = [
  {
    name: 'RDP'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
]
var publicIpAddressName = '${virtualMachineName}-publicip-${uniqueString(virtualMachineName)}'
var publicIpAddressType = 'Dynamic'
var publicIpAddressSku = 'Basic'
var diskConfigurationType = 'NEW'
var nsgId = networkSecurityGroupName_resource.id
var subnetRef = resourceId(existingVnetResourceGroup, 'Microsoft.Network/virtualNetWorks/subnets', existingVirtualNetworkName, existingSubnetName)
var dataDisksLuns = array(range(0, sqlDataDisksCount))
var logDisksLuns = array(range(sqlDataDisksCount, sqlLogDisksCount))
var dataDisks = {
  createOption: 'empty'
  caching: 'ReadOnly'
  writeAcceleratorEnabled: false
  storageAccountType: 'Premium_LRS'
  diskSizeGB: 1023
}
var tempDbPath = 'D:\\SQLTemp'

resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2020-06-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIpAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
    publicIpAddressName_resource
  ]
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: imageOffer
        sku: sqlSku
        version: 'latest'
      }
      copy: [
        {
          name: 'dataDisks'
          count: (sqlDataDisksCount + sqlLogDisksCount)
          input: {
            lun: copyIndex('dataDisks')
            createOption: dataDisks.createOption
            caching: ((copyIndex('dataDisks') >= sqlDataDisksCount) ? 'None' : dataDisks.caching)
            writeAcceleratorEnabled: dataDisks.writeAcceleratorEnabled
            diskSizeGB: dataDisks.diskSizeGB
            managedDisk: {
              storageAccountType: dataDisks.storageAccountType
            }
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVmAgent: true
      }
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

resource Microsoft_SqlVirtualMachine_SqlVirtualMachines_virtualMachineName 'Microsoft.SqlVirtualMachine/SqlVirtualMachines@2017-03-01-preview' = {
  name: virtualMachineName
  location: location
  properties: {
    virtualMachineResourceId: virtualMachineName_resource.id
    sqlManagement: 'Full'
    SqlServerLicenseType: 'PAYG'
    StorageConfigurationSettings: {
      DiskConfigurationType: diskConfigurationType
      StorageWorkloadType: storageWorkloadType
      SQLDataSettings: {
        LUNs: dataDisksLuns
        DefaultFilePath: dataPath
      }
      SQLLogSettings: {
        Luns: logDisksLuns
        DefaultFilePath: logPath
      }
      SQLTempDbSettings: {
        DefaultFilePath: tempDbPath
      }
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

output adminUsername_output string = adminUsername
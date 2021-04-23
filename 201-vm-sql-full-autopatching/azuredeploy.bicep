@description('SQL Server Virtual Machine Name')
param virtualMachineName string = 'vmName'

@allowed([
  'Standard_DS1'
  'Standard_DS2'
  'Standard_DS3'
  'Standard_DS4'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
])
@description('SQL Server Virtual Machine Size')
param virtualMachineSize string = 'Standard_DS4'

@description('SQL Server Virtual Machine Administrator User Name')
param adminUsername string

@description('SQL Server Virtual Machine Administrator Password')
@secure()
param adminPassword string

@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('SQL Server Virtual Machine Storage Account Type')
param storageAccountType string = 'Premium_LRS'

@description('SQL Server Virtual Machine Virtual Network Name')
param virtualNetworkName string

@description('SQL Server Virtual Machine Network Interface Name')
param networkInterfaceName string

@description('SQL Server Virtual Machine Network Security Group Name')
param networkSecurityGroupName string

@description('SQL Server Virtual Machine Subnet Name')
param addressPrefix string = '10.0.0.0/16'

@description('SQL Server Virtual Machine Subnet Name')
param subnetName string = 'default'

@description('SQL Server Virtual Machine Subnet Name')
param subnetPrefix string = '10.0.0.0/24'

@description('SQL Server Virtual Machine Public IP Address Name')
param publicIpAddressName string

@description('SQL Server Virtual Machine Public IP Address Type')
param publicIpAddressType string = 'Dynamic'

@description('SQL Server Virtual Machine SQL Connectivity Type')
param sqlConnectivityType string = 'Public'

@description('SQL Server Virtual Machine SQL Port Number')
param sqlPortNumber int = 1579

@description('SQL Server Virtual Machine Data Disk Count')
param sqlStorageDisksCount int = 2

@allowed([
  'GENERAL'
  'OLTP'
  'DW'
])
@description('SQL Server Virtual Machine Workload Type: GENERAL - general work load; DW - datawear house work load; OLTP - Transactional processing work load')
param sqlStorageWorkloadType string = 'GENERAL'

@allowed([
  'Everyday'
  'Never'
  'Sunday'
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
])
@description('SQL Server Auto Patching Day of A Week')
param sqlAutopatchingDayOfWeek string = 'Sunday'

@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
  '10'
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
  '17'
  '18'
  '19'
  '20'
  '21'
  '22'
  '23'
])
@description('SQL Server Auto Patching Starting Hour')
param sqlAutopatchingStartHour string = '2'

@allowed([
  '30'
  '60'
  '90'
  '120'
  '150'
  '180'
])
@description('SQL Server Auto Patching Duration Window in minutes')
param sqlAutopatchingWindowDuration string = '60'

@description('SQL Server Authentication Login Account Name')
param sqlAuthenticationLogin string = 'mysa'

@description('SQL Server Authentication Login Account Password')
@secure()
param sqlAuthenticationPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: virtualMachineName
  location: location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: 'true'
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2016SP1-WS2016'
        sku: 'Enterprise'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 1023
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: storageAccountType
          }
        }
        {
          createOption: 'Empty'
          lun: 1
          diskSizeGB: 1023
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: storageAccountType
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
  }
}

resource virtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: virtualMachineName_resource
  name: 'SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {
      AutoTelemetrySettings: {
        Region: location
      }
      AutoPatchingSettings: {
        PatchCategory: 'WindowsMandatoryUpdates'
        Enable: true
        DayOfWeek: sqlAutopatchingDayOfWeek
        MaintenanceWindowStartingHour: sqlAutopatchingStartHour
        MaintenanceWindowDuration: sqlAutopatchingWindowDuration
      }
    }
  }
}

module prepareSqlVmDeployment '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-sql-full-autopatching/nested/preparingSqlServerSa.json*/ = {
  name: 'prepareSqlVmDeployment'
  params: {
    sqlVMName: virtualMachineName
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    sqlUsername: sqlAuthenticationLogin
    sqlPassword: sqlAuthenticationPassword
    disksCount: sqlStorageDisksCount
    diskSizeInGB: 1023
    sqlEnginePort: sqlPortNumber
    workloadType: sqlStorageWorkloadType
    connectionType: sqlConnectivityType
    sqlVMPrepareModulesURL: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-sql-full-autopatching/scripts/PrepareSqlServer.ps1.zip'
    sqlVMPrepareConfigurationFunction: 'PrepareSqlServerSa.ps1\\PrepareSqlServerSa'
  }
  dependsOn: [
    virtualMachineName_SqlIaasExtension
  ]
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIpAddressName_resource
    networkSecurityGroupName_resource
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-sql'
        properties: {
          priority: 1500
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output adminUsername string = adminUsername
@description('SQL Server Virtual Machine Name')
param virtualMachineName string

@allowed([
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS11_v2'
  'Standard_DS12_v2'
  'Standard_DS13_v2'
  'Standard_DS14_v2'
])
@description('SQL Server Virtual Machine Size')
param virtualMachineSize string = 'Standard_DS4_v2'

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
  '24'
  '25'
  '26'
  '27'
  '28'
  '29'
  '30'
])
@description('SQL Server Auto Backup Retention Period')
param sqlAutobackupRetentionPeriod string = '30'

@description('SQL Server Auto Backup Storage Account Name')
param sqlAutobackupStorageAccountName string

@description('SQL Server Auto Backup Encryption Password')
param sqlAutobackupEncryptionPassword string

@description('SQL Server Authentication Login Account Name')
param sqlAuthenticationLogin string = 'mysa'

@description('SQL Server Authentication Login Account Password')
@secure()
param sqlAuthenticationPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('URI to artifacts location')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-sql-full-autobackup/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2014SP2-WS2012R2'
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
          managedDisk: {
            storageAccountType: storageAccountType
          }
          lun: 0
          diskSizeGB: 1023
          caching: 'ReadOnly'
        }
        {
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: storageAccountType
          }
          lun: 1
          diskSizeGB: 1023
          caching: 'ReadOnly'
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

resource virtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
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
      AutoBackupSettings: {
        Enable: true
        RetentionPeriod: sqlAutobackupRetentionPeriod
        EnableEncryption: true
      }
    }
    protectedSettings: {
      StorageUrl: reference(sqlAutobackupStorageAccountName_resource.id, '2015-06-15').primaryEndpoints.blob
      StorageAccessKey: listKeys(sqlAutobackupStorageAccountName_resource.id, '2015-06-15').key1
      Password: sqlAutobackupEncryptionPassword
    }
  }
}

module prepareSqlVmDeployment '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/preparingSqlServerSa.json', parameters('_artifactsLocationSasToken')))]*/ = {
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
    sqlVMPrepareModulesURL: uri(artifactsLocation, 'scripts/PrepareSqlServer.ps1.zip${artifactsLocationSasToken}')
    sqlVMPrepareConfigurationFunction: 'PrepareSqlServerSa.ps1\\PrepareSqlServerSa'
  }
  dependsOn: [
    virtualMachineName_SqlIaasExtension
  ]
}

resource sqlAutobackupStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: sqlAutobackupStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
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
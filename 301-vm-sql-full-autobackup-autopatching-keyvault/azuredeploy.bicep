param virtualMachineName string {
  metadata: {
    description: 'SQL Server Virtual Machine Name'
  }
}
param virtualMachineSize string {
  allowed: [
    'Standard_DS1'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS11'
    'Standard_DS12'
    'Standard_DS13'
    'Standard_DS14'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Size'
  }
  default: 'Standard_DS4'
}
param adminUsername string {
  metadata: {
    description: 'SQL Server Virtual Machine Administrator User Name'
  }
}
param adminPassword string {
  metadata: {
    description: 'SQL Server Virtual Machine Administrator Password'
  }
  secure: true
}
param storageAccountName string {
  metadata: {
    description: 'SQL Server Virtual Machine Storage Account Name'
  }
}
param storageAccountType string {
  allowed: [
    'Premium_LRS'
    'Standard_LRS'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Storage Account Type'
  }
  default: 'Premium_LRS'
}
param virtualNetworkName string {
  metadata: {
    description: 'SQL Server Virtual Machine Virtual Network Name'
  }
}
param networkInterfaceName string {
  metadata: {
    description: 'SQL Server Virtual Machine Network Interface Name'
  }
}
param networkSecurityGroupName string {
  metadata: {
    description: 'SQL Server Virtual Machine Network Security Group Name'
  }
}
param addressPrefix string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: 'default'
}
param subnetPrefix string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: '10.0.0.0/24'
}
param publicIpAddressName string {
  metadata: {
    description: 'SQL Server Virtual Machine Public IP Address Name'
  }
}
param publicIpAddressType string {
  metadata: {
    description: 'SQL Server Virtual Machine Public IP Address Type'
  }
  default: 'Dynamic'
}
param sqlConnectivityType string {
  metadata: {
    description: 'SQL Server Virtual Machine SQL Connectivity Type'
  }
  default: 'Public'
}
param sqlPortNumber int {
  metadata: {
    description: 'SQL Server Virtual Machine SQL Port Number'
  }
  default: 1579
}
param sqlStorageDisksCount int {
  metadata: {
    description: 'SQL Server Virtual Machine Data Disk Count'
  }
  default: '2'
}
param sqlStorageWorkloadType string {
  allowed: [
    'GENERAL'
    'OLTP'
    'DW'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Workload Type: GENERAL - general work load; DW - datawear house work load; OLTP - Transactional processing work load'
  }
  default: 'GENERAL'
}
param sqlAutopatchingDayOfWeek string {
  allowed: [
    'Everyday'
    'Never'
    'Sunday'
    'Monday'
    'Tuesday'
    'Wednesday'
    'Thursday'
    'Friday'
    'Saturday'
  ]
  metadata: {
    description: 'SQL Server Auto Patching Day of A Week'
  }
  default: 'Sunday'
}
param sqlAutopatchingStartHour string {
  allowed: [
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
  ]
  metadata: {
    description: 'SQL Server Auto Patching Starting Hour'
  }
  default: '2'
}
param sqlAutopatchingWindowDuration string {
  allowed: [
    '30'
    '60'
    '90'
    '120'
    '150'
    '180'
  ]
  metadata: {
    description: 'SQL Server Auto Patching Duration Window in minutes'
  }
  default: '60'
}
param sqlAutobackupRetentionPeriod string {
  allowed: [
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
  ]
  metadata: {
    description: 'SQL Server Auto Backup Retention Period'
  }
  default: '30'
}
param sqlAutobackupStorageAccountName string {
  metadata: {
    description: 'SQL Server Auto Backup Storage Account Name'
  }
}
param sqlAutobackupEncryptionPassword string {
  metadata: {
    description: 'SQL Server Auto Backup Encryption Password'
  }
}
param sqlAkvCredentialName string {
  metadata: {
    description: 'SQL credential name to create on the SQL Server virtual machine'
  }
}
param sqlAkvUrl string {
  metadata: {
    description: 'Azure Key Vault URL'
  }
}
param sqlAkvPrincipalName string {
  metadata: {
    description: 'Azure Key Vault principal name or id'
  }
}
param sqlAkvPrincipalSecret string {
  metadata: {
    description: 'Azure Key Vault principal secret'
  }
  secure: true
}
param sqlAuthenticationLogin string {
  metadata: {
    description: 'SQL Server Authentication Login Account Name'
  }
  default: 'mysa'
}
param sqlAuthenticationPassword string {
  metadata: {
    description: 'SQL Server Authentication Login Account Password'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource virtualMachineName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
        offer: 'SQL2014SP1-WS2012R2'
        sku: 'Enterprise'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk1'
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 1023
          caching: 'ReadOnly'
        }
        {
          name: '${virtualMachineName}_DataDisk2'
          createOption: 'Empty'
          lun: 1
          diskSizeGB: 1023
          caching: 'ReadOnly'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_res.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_res
  ]
}

resource virtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${virtualMachineName}/SqlIaasExtension'
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
      AutoBackupSettings: {
        Enable: true
        RetentionPeriod: sqlAutobackupRetentionPeriod
        EnableEncryption: true
      }
      KeyVaultCredentialSettings: {
        Enable: true
        CredentialName: sqlAkvCredentialName
      }
    }
    protectedSettings: {
      StorageUrl: reference(sqlAutobackupStorageAccountName_res.id, '2015-06-15').primaryEndpoints.blob
      StorageAccessKey: listKeys(sqlAutobackupStorageAccountName_res.id, '2015-06-15').key1
      Password: sqlAutobackupEncryptionPassword
      PrivateKeyVaultCredentialSettings: {
        AzureKeyVaultUrl: sqlAkvUrl
        ServicePrincipalName: sqlAkvPrincipalName
        ServicePrincipalSecret: sqlAkvPrincipalSecret
      }
    }
  }
  dependsOn: [
    virtualMachineName_res
  ]
}

module prepareSqlVmDeployment '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-sql-full/nested/preparingSqlServerSa.json*/ = {
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
    sqlVMPrepareModulesURL: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-sql-full/scripts/PrepareSqlServer.ps1.zip'
    sqlVMPrepareConfigurationFunction: 'PrepareSqlServerSa.ps1\\PrepareSqlServerSa'
  }
  dependsOn: [
    virtualMachineName_SqlIaasExtension
  ]
}

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource sqlAutobackupStorageAccountName_res 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: sqlAutobackupStorageAccountName
  location: location
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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

resource networkInterfaceName_res 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: resourceId(resourceGroup().Name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().Name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    }
  }
  dependsOn: [
    virtualNetworkName_res
    publicIpAddressName_res
    networkSecurityGroupName_res
  ]
}

resource publicIpAddressName_res 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName_res 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
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

output adminUsername_out string = adminUsername
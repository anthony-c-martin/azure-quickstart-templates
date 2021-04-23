@minLength(1)
@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Username for SA of the database')
param dbSAUsername string

@description('Password for SA of the database')
@secure()
param dbSAUserPassword string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@description('The SQL Iamge for the VM. This will pick a fully patched image of this given SQL Image')
param sqlImageVersion string = 'SQL2014SP2-WS2012R2'

@allowed([
  'Enterprise'
  'Evaluation'
])
@description('The SQL SKU, for SQL CTP Versions the only available is evaluation')
param sqlImageSKU string = 'Enterprise'

@minLength(1)
@description('Prefix of the Virtual Machines (Prefix-RS, Prefix-Catalog)')
param vmPrefix string = 'SSRS'

@description('The size of the VM Created')
param vmSize string = 'Standard_DS3'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('VHD storage type')
param vhdStorageType string = 'Premium_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var sqlImagePublisher = 'MicrosoftSQLServer'
var sqlImageOffer = sqlImageVersion
var sqlImageSku_var = sqlImageSKU
var OSDiskName = 'osdiskforwindowssimple'
var dataDiskName = 'dataDisk'
var nicName_var = 'SSRSNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vhdStorageType_var = vhdStorageType
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vhdStorageContainerName = 'vhds'
var vmNameRs_var = '${vmPrefix}-RS'
var vmSizeRs = vmSize
var vmImageOfferRs = sqlImageOffer
var vmNameCatalog_var = '${vmPrefix}-Catalog'
var virtualNetworkName_var = 'SSRSVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var vhdStorageNameRs_var = '${uniqueString(resourceGroup().id)}vhdrs'
var vhdStorageNameCatalog_var = '${uniqueString(resourceGroup().id)}vhdcatalog'
var catalogPublicIpId = 'Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}0'
var dnsName = dnsLabelPrefix
var sqlSAConfigurationConfigurationFunction = 'PrepareSqlServerSa.ps1\\PrepareSqlServerSa'
var rsConfigurationConfigurationFunction = 'PrepareRsServer.ps1\\PrepareSSRSServer'
var sqlModuleUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sql-reporting-services-sql-server/DSC/PrepareSqlServer.ps1.zip'
var diagnosticsStorageAccountName_var = '${uniqueString(resourceGroup().id)}diag'
var diagnosticsStorageAccountResourceGroup = resourceGroup().name
var accountid = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${diagnosticsStorageAccountResourceGroup}/providers/Microsoft.Storage/storageAccounts/${diagnosticsStorageAccountName_var}'
var wadlogs = '<WadCfg> <DiagnosticMonitorConfiguration overallQuotaInMB="4096" xmlns="https://schemas.microsoft.com/ServiceHosting/2010/10/DiagnosticsConfiguration"> <DiagnosticInfrastructureLogs scheduledTransferLogLevelFilter="Error"/> <WindowsEventLog scheduledTransferPeriod="PT1M" > <DataSource name="Application!*[System[(Level = 1 or Level = 2)]]" /> <DataSource name="Security!*[System[(Level = 1 or Level = 2)]]" /> <DataSource name="System!*[System[(Level = 1 or Level = 2)]]" /></WindowsEventLog>'
var wadperfcounters1 = '<PerformanceCounters scheduledTransferPeriod="PT1M"><PerformanceCounterConfiguration counterSpecifier="\\Processor(_Total)\\% Processor Time" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU utilization" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor(_Total)\\% Privileged Time" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU privileged time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor(_Total)\\% User Time" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU user time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor Information(_Total)\\Processor Frequency" sampleRate="PT15S" unit="Count"><annotation displayName="CPU frequency" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\System\\Processes" sampleRate="PT15S" unit="Count"><annotation displayName="Processes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Process(_Total)\\Thread Count" sampleRate="PT15S" unit="Count"><annotation displayName="Threads" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Process(_Total)\\Handle Count" sampleRate="PT15S" unit="Count"><annotation displayName="Handles" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\% Committed Bytes In Use" sampleRate="PT15S" unit="Percent"><annotation displayName="Memory usage" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\Available Bytes" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\Committed Bytes" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory committed" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\Commit Limit" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory commit limit" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\% Disk Time" sampleRate="PT15S" unit="Percent"><annotation displayName="Disk active time" locale="en-us"/></PerformanceCounterConfiguration>'
var wadperfcounters2 = '<PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\% Disk Read Time" sampleRate="PT15S" unit="Percent"><annotation displayName="Disk active read time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\% Disk Write Time" sampleRate="PT15S" unit="Percent"><annotation displayName="Disk active write time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Transfers/sec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk operations" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Reads/sec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk read operations" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Writes/sec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk write operations" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Bytes/sec" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk speed" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Read Bytes/sec" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk read speed" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk(_Total)\\Disk Write Bytes/sec" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk write speed" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\LogicalDisk(_Total)\\% Free Space" sampleRate="PT15S" unit="Percent"><annotation displayName="Disk free space (percentage)" locale="en-us"/></PerformanceCounterConfiguration></PerformanceCounters>'
var wadcfgxstart = '${wadlogs}${wadperfcounters1}${wadperfcounters2}<Metrics resourceId="'
var wadmetricsresourceid = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachines/'
var wadcfgxend = '"><MetricAggregation scheduledTransferPeriod="PT1H"/><MetricAggregation scheduledTransferPeriod="PT1M"/></Metrics></DiagnosticMonitorConfiguration></WadCfg>'

resource vhdStorageNameRs 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: vhdStorageNameRs_var
  location: location
  tags: {
    displayName: 'DataStorageAccountRs'
  }
  properties: {
    accountType: vhdStorageType_var
  }
}

resource vhdStorageNameCatalog 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: vhdStorageNameCatalog_var
  location: location
  tags: {
    displayName: 'DataStorageAccountCatalog'
  }
  properties: {
    accountType: vhdStorageType_var
  }
}

resource diagnosticsStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: diagnosticsStorageAccountName_var
  location: location
  tags: {
    displayName: 'DiagnosticsStorageAccount'
  }
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, 1): {
  name: concat(publicIPAddressName_var, i)
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: concat(dnsName, i)
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'VirtualNetwork'
  }
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

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, 1): {
  name: concat(nicName_var, i)
  location: location
  tags: {
    displayName: 'NetworkInterface'
  }
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

resource vmNameRs 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmNameRs_var
  location: location
  tags: {
    displayName: 'RsMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSizeRs
    }
    osProfile: {
      computerName: vmNameRs_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: sqlImagePublisher
        offer: vmImageOfferRs
        sku: sqlImageSku_var
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameRs_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          name: '${vmNameRs_var}_DataDisk1'
          createOption: 'Empty'
          caching: 'ReadOnly'
          diskSizeGB: '1023'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Microsoft_Network_networkInterfaces_nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${diagnosticsStorageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    vhdStorageNameRs
    diagnosticsStorageAccountName
  ]
}

resource vmNameRs_Microsoft_Insights_VMDiagnosticsSettings 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmNameRs
  name: 'Microsoft.Insights.VMDiagnosticsSettings'
  location: location
  tags: {
    displayName: 'Diagnostics'
  }
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'IaaSDiagnostics'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {
      xmlCfg: base64(concat(wadcfgxstart, wadmetricsresourceid, vmNameRs_var, wadcfgxend))
      storageAccount: diagnosticsStorageAccountName_var
    }
    protectedSettings: {
      storageAccountName: diagnosticsStorageAccountName_var
      storageAccountKey: listkeys(accountid, '2015-06-15').key1
      storageAccountEndPoint: 'https://core.windows.net'
    }
  }
}

resource vmNameRs_SSRSConfiguration 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmNameRs
  name: 'SSRSConfiguration'
  location: location
  tags: {
    displayName: 'SSRSConfiguration'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: sqlModuleUrl
      configurationFunction: rsConfigurationConfigurationFunction
      properties: {
        SQLSAAdminAuthCreds: {
          userName: dbSAUsername
          Password: 'privateSettingsRef:SAPassword'
        }
        CatalogMachine: reference(catalogPublicIpId, '2015-06-15').dnsSettings.fqdn
      }
    }
    protectedSettings: {
      Items: {
        SAPassword: dbSAUserPassword
      }
    }
  }
  dependsOn: [
    vmNameCatalog_SQLConfigurationMixedAuth
  ]
}

resource vmNameCatalog 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmNameCatalog_var
  location: location
  tags: {
    displayName: 'CatalogMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSizeRs
    }
    osProfile: {
      computerName: vmNameCatalog_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: sqlImagePublisher
        offer: sqlImageOffer
        sku: sqlImageSku_var
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameCatalog_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          name: '${vmNameCatalog_var}_DataDisk1'
          createOption: 'Empty'
          caching: 'ReadOnly'
          diskSizeGB: '1023'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, 0))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${diagnosticsStorageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    vhdStorageNameCatalog
    diagnosticsStorageAccountName
    'Microsoft.Network/networkInterfaces/${nicName_var}0'
  ]
}

resource vmNameCatalog_SQLConfigurationMixedAuth 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmNameCatalog
  name: 'SQLConfigurationMixedAuth'
  location: location
  tags: {
    displayName: 'SQLConfigurationMixedAuth'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: sqlModuleUrl
      configurationFunction: sqlSAConfigurationConfigurationFunction
      properties: {
        SQLAdminAuthCreds: {
          userName: adminUsername
          Password: 'privateSettingsRef:AdminPassword'
        }
        SQLAuthCreds: {
          userName: dbSAUsername
          Password: 'privateSettingsRef:SAPassword'
        }
        DisksCount: 1
        DiskSizeInGB: 1023
        DatabaseEnginePort: 1433
        WorkloadType: 'General'
        ConnectionType: 'Public'
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
        SAPassword: dbSAUserPassword
      }
    }
  }
}

resource vmNameCatalog_Microsoft_Insights_VMDiagnosticsSettings 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmNameCatalog
  name: 'Microsoft.Insights.VMDiagnosticsSettings'
  location: location
  tags: {
    displayName: 'Diagnostics'
  }
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'IaaSDiagnostics'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {
      xmlCfg: base64(concat(wadcfgxstart, wadmetricsresourceid, vmNameCatalog_var, wadcfgxend))
      storageAccount: diagnosticsStorageAccountName_var
    }
    protectedSettings: {
      storageAccountName: diagnosticsStorageAccountName_var
      storageAccountKey: listkeys(accountid, '2015-06-15').key1
      storageAccountEndPoint: 'https://core.windows.net'
    }
  }
}

resource Microsoft_Network_networkInterfaces_nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'RSNetworkInterface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          publicIPAddress: {
            id: Microsoft_Network_publicIPAddresses_publicIPAddressName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource Microsoft_Network_publicIPAddresses_publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: 'PublicRSIPAddress'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
  dependsOn: []
}
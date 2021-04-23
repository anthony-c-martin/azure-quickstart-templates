@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  '2013'
  '2016'
  '2019'
])
@description('Version of SharePoint farm to create.')
param sharePointVersion string = '2019'

@minLength(2)
@description('"[Prefix]" of public DNS name of VMs, as used in "[Prefix]-[VMName].[region].cloudapp.azure.com"')
param dnsLabelPrefix string

@minLength(5)
@description('FQDN of the AD forest to create')
param domainFQDN string = 'contoso.local'

@allowed([
  0
  1
  2
  3
  4
])
@description('Number of MinRole Front-end to add to the farm. The MinRole type can be changed later as needed.')
param numberOfAdditionalFrontEnd int = 0

@minLength(1)
@description('Name of the AD and SharePoint administrator. \'administrator\' is not allowed')
param adminUserName string = 'yvand'

@minLength(8)
@description('Input must meet password complexity requirements as documented for property \'adminPassword\' in https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/virtualmachines-create-or-update')
@secure()
param adminPassword string

@minLength(8)
@description('Password for all service account and SharePoint passphrase. It must meet password complexity requirements as documented for property \'adminPassword\' in https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/virtualmachines-create-or-update')
@secure()
param serviceAccountsPassword string

@description('Size of the DC VM')
param vmDCSize string = 'Standard_DS2_v2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Premium_LRS'
])
@description('Type of storage for the managed disks. Allowed values are \'Standard_LRS\', \'Standard_GRS\' and \'Premium_LRS\'')
param vmDCStorageAccountType string = 'Standard_LRS'

@description('Size of the SQL VM')
param vmSQLSize string = 'Standard_E2ds_v4'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Premium_LRS'
])
@description('Type of storage for the managed disks. Allowed values are \'Standard_LRS\', \'Standard_GRS\' and \'Premium_LRS\'')
param vmSQLStorageAccountType string = 'Standard_LRS'

@description('Size of the SharePoint VM')
param vmSPSize string = 'Standard_E2ds_v4'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Premium_LRS'
])
@description('Type of storage for the managed disks. Allowed values are \'Standard_LRS\', \'Standard_GRS\' and \'Premium_LRS\'')
param vmSPStorageAccountType string = 'Standard_LRS'

@minLength(2)
@allowed([
  'Dateline Standard Time'
  'UTC-11'
  'Aleutian Standard Time'
  'Hawaiian Standard Time'
  'Marquesas Standard Time'
  'Alaskan Standard Time'
  'UTC-09'
  'Pacific Standard Time (Mexico)'
  'UTC-08'
  'Pacific Standard Time'
  'US Mountain Standard Time'
  'Mountain Standard Time (Mexico)'
  'Mountain Standard Time'
  'Central America Standard Time'
  'Central Standard Time'
  'Easter Island Standard Time'
  'Central Standard Time (Mexico)'
  'Canada Central Standard Time'
  'SA Pacific Standard Time'
  'Eastern Standard Time (Mexico)'
  'Eastern Standard Time'
  'Haiti Standard Time'
  'Cuba Standard Time'
  'US Eastern Standard Time'
  'Turks And Caicos Standard Time'
  'Paraguay Standard Time'
  'Atlantic Standard Time'
  'Venezuela Standard Time'
  'Central Brazilian Standard Time'
  'SA Western Standard Time'
  'Pacific SA Standard Time'
  'Newfoundland Standard Time'
  'Tocantins Standard Time'
  'E. South America Standard Time'
  'SA Eastern Standard Time'
  'Argentina Standard Time'
  'Greenland Standard Time'
  'Montevideo Standard Time'
  'Magallanes Standard Time'
  'Saint Pierre Standard Time'
  'Bahia Standard Time'
  'UTC-02'
  'Mid-Atlantic Standard Time'
  'Azores Standard Time'
  'Cape Verde Standard Time'
  'UTC'
  'GMT Standard Time'
  'Greenwich Standard Time'
  'Sao Tome Standard Time'
  'Morocco Standard Time'
  'W. Europe Standard Time'
  'Central Europe Standard Time'
  'Romance Standard Time'
  'Central European Standard Time'
  'W. Central Africa Standard Time'
  'Jordan Standard Time'
  'GTB Standard Time'
  'Middle East Standard Time'
  'Egypt Standard Time'
  'E. Europe Standard Time'
  'Syria Standard Time'
  'West Bank Standard Time'
  'South Africa Standard Time'
  'FLE Standard Time'
  'Israel Standard Time'
  'Kaliningrad Standard Time'
  'Sudan Standard Time'
  'Libya Standard Time'
  'Namibia Standard Time'
  'Arabic Standard Time'
  'Turkey Standard Time'
  'Arab Standard Time'
  'Belarus Standard Time'
  'Russian Standard Time'
  'E. Africa Standard Time'
  'Iran Standard Time'
  'Arabian Standard Time'
  'Astrakhan Standard Time'
  'Azerbaijan Standard Time'
  'Russia Time Zone 3'
  'Mauritius Standard Time'
  'Saratov Standard Time'
  'Georgian Standard Time'
  'Volgograd Standard Time'
  'Caucasus Standard Time'
  'Afghanistan Standard Time'
  'West Asia Standard Time'
  'Ekaterinburg Standard Time'
  'Pakistan Standard Time'
  'Qyzylorda Standard Time'
  'India Standard Time'
  'Sri Lanka Standard Time'
  'Nepal Standard Time'
  'Central Asia Standard Time'
  'Bangladesh Standard Time'
  'Omsk Standard Time'
  'Myanmar Standard Time'
  'SE Asia Standard Time'
  'Altai Standard Time'
  'W. Mongolia Standard Time'
  'North Asia Standard Time'
  'N. Central Asia Standard Time'
  'Tomsk Standard Time'
  'China Standard Time'
  'North Asia East Standard Time'
  'Singapore Standard Time'
  'W. Australia Standard Time'
  'Taipei Standard Time'
  'Ulaanbaatar Standard Time'
  'Aus Central W. Standard Time'
  'Transbaikal Standard Time'
  'Tokyo Standard Time'
  'North Korea Standard Time'
  'Korea Standard Time'
  'Yakutsk Standard Time'
  'Cen. Australia Standard Time'
  'AUS Central Standard Time'
  'E. Australia Standard Time'
  'AUS Eastern Standard Time'
  'West Pacific Standard Time'
  'Tasmania Standard Time'
  'Vladivostok Standard Time'
  'Lord Howe Standard Time'
  'Bougainville Standard Time'
  'Russia Time Zone 10'
  'Magadan Standard Time'
  'Norfolk Standard Time'
  'Sakhalin Standard Time'
  'Central Pacific Standard Time'
  'Russia Time Zone 11'
  'New Zealand Standard Time'
  'UTC+12'
  'Fiji Standard Time'
  'Kamchatka Standard Time'
  'Chatham Islands Standard Time'
  'UTC+13'
  'Tonga Standard Time'
  'Samoa Standard Time'
  'Line Islands Standard Time'
])
@description('Time zone of the virtual machines. Type "[TimeZoneInfo]::GetSystemTimeZones().Id" in PowerShell to get the list.')
param vmsTimeZone string = 'Romance Standard Time'

@minLength(4)
@maxLength(4)
@description('The time at which VMs will be automatically shutdown (24h HHmm format). Set value to \'9999\' to NOT configure the auto shutdown.')
param vmsAutoShutdownTime string = '1900'

@allowed([
  'Yes'
  'No'
])
@description('Enable automatic Windows Updates.')
param enableAutomaticUpdates string = 'Yes'

@allowed([
  'Yes'
  'No'
])
@description('Enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.')
param enableHybridBenefitServerLicenses string = 'No'

@description('Size in Gb of the additional data disk attached to SharePoint VMs. Set to 0 to not create it')
param sharePointDataDiskSize int = 0

@allowed([
  'Yes'
  'No'
])
@description('Specify if Azure Bastion should be provisioned. See https://azure.microsoft.com/en-us/services/azure-bastion for more information.')
param addAzureBastion string = 'No'

@allowed([
  'Yes'
  'No'
])
@description('Specify if each VM should have a public IP and be reachable from Internet.')
param addPublicIPAddressToEachVM string = 'Yes'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation. When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var generalSettings = {
  vmDCName: 'DC'
  vmSQLName: 'SQL'
  vmSPName: 'SP'
  vmFEName: 'FE'
  sqlAlias: 'SQLAlias'
  spSuperUserName: 'spSuperUser'
  spSuperReaderName: 'spSuperReader'
  adfsSvcUserName: 'adfssvc'
  adfsSvcPassword: serviceAccountsPassword
  sqlSvcUserName: 'sqlsvc'
  sqlSvcPassword: serviceAccountsPassword
  spSetupUserName: 'spsetup'
  spSetupPassword: serviceAccountsPassword
  spFarmUserName: 'spfarm'
  spFarmPassword: serviceAccountsPassword
  spSvcUserName: 'spsvc'
  spSvcPassword: serviceAccountsPassword
  spAppPoolUserName: 'spapppool'
  spAppPoolPassword: serviceAccountsPassword
  spPassphrase: serviceAccountsPassword
}
var networkSettings = {
  vNetPrivateName: '${resourceGroup().name}-vnet'
  vNetPrivatePrefix: '10.0.0.0/16'
  subnetDCName: 'Subnet-DC'
  subnetDCPrefix: '10.0.1.0/24'
  subnetSQLName: 'Subnet-SQL'
  subnetSQLPrefix: '10.0.2.0/24'
  subnetSPName: 'Subnet-SP'
  subnetSPPrefix: '10.0.3.0/24'
  nsgSubnetDCName: 'NSG-Subnet-DC'
  nsgSubnetSQLName: 'NSG-Subnet-SQL'
  nsgSubnetSPName: 'NSG-Subnet-SP'
  vmDCPublicIPNicAssociation: {
    id: vmDC_vmPublicIPName.id
  }
  vmSQLPublicIPNicAssociation: {
    id: vmSQL_vmPublicIPName.id
  }
  vmSPPublicIPNicAssociation: {
    id: vmSP_vmPublicIPName.id
  }
  vmFEPublicIPNicAssociation: {
    id: resourceId('Microsoft.Network/publicIPAddresses', vmFE.vmPublicIPName)
  }
  nsgRuleAllowRdpPort: [
    {
      name: 'allow-rdp-rule'
      properties: {
        description: 'Allow RDP'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 110
        direction: 'Inbound'
      }
    }
  ]
}
var vmDC = {
  vmImagePublisher: 'MicrosoftWindowsServer'
  vmImageOffer: 'WindowsServer'
  vmImageSKU: '2019-Datacenter'
  vmOSDiskName: 'Disk-DC-OS'
  vmVmSize: vmDCSize
  vmNicName: 'NIC-${generalSettings.vmDCName}-0'
  nicPrivateIPAddress: '10.0.1.4'
  vmPublicIPName: 'PublicIP-${generalSettings.vmDCName}'
  vmPublicIPDnsName: toLower(replace('${dnsLabelPrefix}-${generalSettings.vmDCName}', '_', '-'))
  shutdownResourceName: 'shutdown-computevm-${generalSettings.vmDCName}'
}
var vmSQL = {
  vmImagePublisher: 'MicrosoftSQLServer'
  vmImageOffer: 'sql2019-ws2019'
  vmImageSKU: 'sqldev'
  vmOSDiskName: 'Disk-SQL-OS'
  vmVmSize: vmSQLSize
  vmNicName: 'NIC-${generalSettings.vmSQLName}-0'
  vmPublicIPName: 'PublicIP-${generalSettings.vmSQLName}'
  vmPublicIPDnsName: toLower(replace('${dnsLabelPrefix}-${generalSettings.vmSQLName}', '_', '-'))
  shutdownResourceName: 'shutdown-computevm-${generalSettings.vmSQLName}'
}
var vmSP = {
  vmImagePublisher: 'MicrosoftSharePoint'
  vmImageOffer: 'MicrosoftSharePointServer'
  vmImageSKU: 'sp${sharePointVersion}'
  vmOSDiskName: 'Disk-SP-OS'
  vmDataDiskName: 'Disk-SP-Data'
  vmVmSize: vmSPSize
  vmNicName: 'NIC-${generalSettings.vmSPName}-0'
  vmPublicIPName: 'PublicIP-${generalSettings.vmSPName}'
  vmPublicIPDnsName: toLower(replace('${dnsLabelPrefix}-${generalSettings.vmSPName}', '_', '-'))
  shutdownResourceName: 'shutdown-computevm-${generalSettings.vmSPName}'
}
var vmFE = {
  vmOSDiskName: 'Disk-FE-OS'
  vmDataDiskName: 'Disk-FE-Data'
  vmNicName: 'NIC-${generalSettings.vmFEName}-0'
  vmPublicIPName: 'PublicIP-${generalSettings.vmFEName}'
  vmPublicIPDnsName: toLower(replace('${dnsLabelPrefix}-${generalSettings.vmFEName}', '_', '-'))
  shutdownResourceName: 'shutdown-computevm-${generalSettings.vmFEName}'
}
var dscConfigureDCVM = {
  scriptFileUri: uri(artifactsLocation, 'dsc/ConfigureDCVM.zip${artifactsLocationSasToken}')
  script: 'ConfigureDCVM.ps1'
  function: 'ConfigureDCVM'
  forceUpdateTag: '1.0'
}
var dscConfigureSQLVM = {
  scriptFileUri: uri(artifactsLocation, 'dsc/ConfigureSQLVM.zip${artifactsLocationSasToken}')
  script: 'ConfigureSQLVM.ps1'
  function: 'ConfigureSQLVM'
  forceUpdateTag: '1.0'
}
var dscConfigureSPVM = {
  scriptFileUri: uri(artifactsLocation, 'dsc/ConfigureSPVM.zip${artifactsLocationSasToken}')
  script: 'ConfigureSPVM.ps1'
  function: 'ConfigureSPVM'
  forceUpdateTag: '1.0'
}
var dscConfigureFEVM = {
  scriptFileUri: uri(artifactsLocation, 'dsc/ConfigureFEVM.zip${artifactsLocationSasToken}')
  script: 'ConfigureFEVM.ps1'
  function: 'ConfigureFEVM'
  forceUpdateTag: '1.0'
}
var vmSPDataDisk = [
  {
    lun: 0
    name: vmSP.vmDataDiskName
    caching: 'ReadWrite'
    createOption: 'Empty'
    diskSizeGB: sharePointDataDiskSize
  }
]
var azureBastion = {
  subnetPrefix: '10.0.4.0/24'
  publicIPDnsName: toLower(replace('${dnsLabelPrefix}-Bastion', '_', '-'))
}

resource networkSettings_nsgSubnetDCName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: networkSettings.nsgSubnetDCName
  location: location
  tags: {
    displayName: networkSettings.nsgSubnetDCName
  }
  properties: {
    securityRules: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.nsgRuleAllowRdpPort : json('null'))
  }
}

resource networkSettings_nsgSubnetSQLName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: networkSettings.nsgSubnetSQLName
  location: location
  tags: {
    displayName: networkSettings.nsgSubnetSQLName
  }
  properties: {
    securityRules: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.nsgRuleAllowRdpPort : json('null'))
  }
}

resource networkSettings_nsgSubnetSPName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: networkSettings.nsgSubnetSPName
  location: location
  tags: {
    displayName: networkSettings.nsgSubnetSPName
  }
  properties: {
    securityRules: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.nsgRuleAllowRdpPort : json('null'))
  }
}

resource networkSettings_vNetPrivateName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: networkSettings.vNetPrivateName
  location: location
  tags: {
    displayName: networkSettings.vNetPrivateName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkSettings.vNetPrivatePrefix
      ]
    }
    subnets: [
      {
        name: networkSettings.subnetDCName
        properties: {
          addressPrefix: networkSettings.subnetDCPrefix
          networkSecurityGroup: {
            id: networkSettings_nsgSubnetDCName.id
          }
        }
      }
      {
        name: networkSettings.subnetSQLName
        properties: {
          addressPrefix: networkSettings.subnetSQLPrefix
          networkSecurityGroup: {
            id: networkSettings_nsgSubnetSQLName.id
          }
        }
      }
      {
        name: networkSettings.subnetSPName
        properties: {
          addressPrefix: networkSettings.subnetSPPrefix
          networkSecurityGroup: {
            id: networkSettings_nsgSubnetSPName.id
          }
        }
      }
    ]
  }
}

resource vmDC_vmPublicIPName 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (addPublicIPAddressToEachVM == 'Yes') {
  name: vmDC.vmPublicIPName
  location: location
  tags: {
    displayName: vmDC.vmPublicIPName
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmDC.vmPublicIPDnsName
    }
  }
}

resource vmDC_vmNicName 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vmDC.vmNicName
  location: location
  tags: {
    displayName: vmDC.vmNicName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmDC.nicPrivateIPAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.vNetPrivateName, networkSettings.subnetDCName)
          }
          publicIPAddress: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.vmDCPublicIPNicAssociation : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_vNetPrivateName
  ]
}

resource generalSettings_vmDCName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: generalSettings.vmDCName
  location: location
  tags: {
    displayName: generalSettings.vmDCName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmDC.vmVmSize
    }
    osProfile: {
      computerName: generalSettings.vmDCName
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        timeZone: vmsTimeZone
        enableAutomaticUpdates: ((enableAutomaticUpdates == 'Yes') ? 'true' : 'false')
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmDC.vmImagePublisher
        offer: vmDC.vmImageOffer
        sku: vmDC.vmImageSKU
        version: 'latest'
      }
      osDisk: {
        name: vmDC.vmOSDiskName
        caching: 'ReadWrite'
        osType: 'Windows'
        createOption: 'FromImage'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: vmDCStorageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmDC_vmNicName.id
        }
      ]
    }
    licenseType: ((enableHybridBenefitServerLicenses == 'Yes') ? 'Windows_Server' : json('null'))
  }
}

resource generalSettings_vmDCName_ConfigureDCVM 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${generalSettings.vmDCName}/ConfigureDCVM'
  location: location
  tags: {
    displayName: 'ConfigureDCVM'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: dscConfigureDCVM.forceUpdateTag
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscConfigureDCVM.scriptFileUri
        script: dscConfigureDCVM.script
        function: dscConfigureDCVM.function
      }
      configurationArguments: {
        domainFQDN: domainFQDN
        PrivateIP: vmDC.nicPrivateIPAddress
      }
      privacy: {
        dataCollection: 'enable'
      }
    }
    protectedSettings: {
      configurationArguments: {
        AdminCreds: {
          UserName: adminUserName
          Password: adminPassword
        }
        AdfsSvcCreds: {
          UserName: generalSettings.adfsSvcUserName
          Password: generalSettings.adfsSvcPassword
        }
      }
    }
  }
  dependsOn: [
    generalSettings_vmDCName
  ]
}

resource vmSQL_vmPublicIPName 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (addPublicIPAddressToEachVM == 'Yes') {
  name: vmSQL.vmPublicIPName
  location: location
  tags: {
    displayName: vmSQL.vmPublicIPName
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmSQL.vmPublicIPDnsName
    }
  }
}

resource vmSQL_vmNicName 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vmSQL.vmNicName
  location: location
  tags: {
    displayName: vmSQL.vmNicName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.vNetPrivateName, networkSettings.subnetSQLName)
          }
          publicIPAddress: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.vmSQLPublicIPNicAssociation : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_vNetPrivateName
  ]
}

resource generalSettings_vmSQLName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: generalSettings.vmSQLName
  location: location
  tags: {
    displayName: generalSettings.vmSQLName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSQL.vmVmSize
    }
    osProfile: {
      computerName: generalSettings.vmSQLName
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        timeZone: vmsTimeZone
        enableAutomaticUpdates: ((enableAutomaticUpdates == 'Yes') ? 'true' : 'false')
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmSQL.vmImagePublisher
        offer: vmSQL.vmImageOffer
        sku: vmSQL.vmImageSKU
        version: 'latest'
      }
      osDisk: {
        name: vmSQL.vmOSDiskName
        caching: 'ReadWrite'
        osType: 'Windows'
        createOption: 'FromImage'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: vmSQLStorageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmSQL_vmNicName.id
        }
      ]
    }
    licenseType: ((enableHybridBenefitServerLicenses == 'Yes') ? 'Windows_Server' : json('null'))
  }
}

resource vmSP_vmPublicIPName 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (addPublicIPAddressToEachVM == 'Yes') {
  name: vmSP.vmPublicIPName
  location: location
  tags: {
    displayName: vmSP.vmPublicIPName
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmSP.vmPublicIPDnsName
    }
  }
}

resource vmSP_vmNicName 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vmSP.vmNicName
  location: location
  tags: {
    displayName: vmSP.vmNicName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.vNetPrivateName, networkSettings.subnetSPName)
          }
          publicIPAddress: ((addPublicIPAddressToEachVM == 'Yes') ? networkSettings.vmSPPublicIPNicAssociation : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_vNetPrivateName
  ]
}

resource generalSettings_vmSPName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: generalSettings.vmSPName
  location: location
  tags: {
    displayName: generalSettings.vmSPName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSP.vmVmSize
    }
    osProfile: {
      computerName: generalSettings.vmSPName
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        timeZone: vmsTimeZone
        enableAutomaticUpdates: ((enableAutomaticUpdates == 'Yes') ? 'true' : 'false')
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmSP.vmImagePublisher
        offer: vmSP.vmImageOffer
        sku: vmSP.vmImageSKU
        version: 'latest'
      }
      osDisk: {
        name: vmSP.vmOSDiskName
        caching: 'ReadWrite'
        osType: 'Windows'
        createOption: 'FromImage'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: vmSPStorageAccountType
        }
      }
      dataDisks: ((sharePointDataDiskSize == 0) ? json('null') : vmSPDataDisk)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmSP_vmNicName.id
        }
      ]
    }
    licenseType: ((enableHybridBenefitServerLicenses == 'Yes') ? 'Windows_Server' : json('null'))
  }
}

resource generalSettings_vmSQLName_ConfigureSQLVM 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${generalSettings.vmSQLName}/ConfigureSQLVM'
  location: location
  tags: {
    displayName: '${generalSettings.vmSQLName}/ConfigureSQLVM'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: dscConfigureSQLVM.forceUpdateTag
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscConfigureSQLVM.scriptFileUri
        script: dscConfigureSQLVM.script
        function: dscConfigureSQLVM.function
      }
      configurationArguments: {
        DNSServer: vmDC.nicPrivateIPAddress
        DomainFQDN: domainFQDN
      }
      privacy: {
        dataCollection: 'enable'
      }
    }
    protectedSettings: {
      configurationArguments: {
        DomainAdminCreds: {
          UserName: adminUserName
          Password: adminPassword
        }
        SqlSvcCreds: {
          UserName: generalSettings.sqlSvcUserName
          Password: generalSettings.sqlSvcPassword
        }
        SPSetupCreds: {
          UserName: generalSettings.spSetupUserName
          Password: generalSettings.spSetupPassword
        }
      }
    }
  }
  dependsOn: [
    generalSettings_vmSQLName
  ]
}

resource generalSettings_vmSPName_ConfigureSPVM 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${generalSettings.vmSPName}/ConfigureSPVM'
  location: location
  tags: {
    displayName: '${generalSettings.vmSPName}/ConfigureSPVM'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: dscConfigureSPVM.forceUpdateTag
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscConfigureSPVM.scriptFileUri
        script: dscConfigureSPVM.script
        function: dscConfigureSPVM.function
      }
      configurationArguments: {
        DNSServer: vmDC.nicPrivateIPAddress
        DomainFQDN: domainFQDN
        DCName: generalSettings.vmDCName
        SQLName: generalSettings.vmSQLName
        SQLAlias: generalSettings.sqlAlias
        SharePointVersion: sharePointVersion
      }
      privacy: {
        dataCollection: 'enable'
      }
    }
    protectedSettings: {
      configurationArguments: {
        DomainAdminCreds: {
          UserName: adminUserName
          Password: adminPassword
        }
        SPSetupCreds: {
          UserName: generalSettings.spSetupUserName
          Password: generalSettings.spSetupPassword
        }
        SPFarmCreds: {
          UserName: generalSettings.spFarmUserName
          Password: generalSettings.spFarmPassword
        }
        SPSvcCreds: {
          UserName: generalSettings.spSvcUserName
          Password: generalSettings.spSvcPassword
        }
        SPAppPoolCreds: {
          UserName: generalSettings.spAppPoolUserName
          Password: generalSettings.spAppPoolPassword
        }
        SPPassphraseCreds: {
          UserName: 'Passphrase'
          Password: generalSettings.spPassphrase
        }
        SPSuperUserCreds: {
          UserName: generalSettings.spSuperUserName
          Password: serviceAccountsPassword
        }
        SPSuperReaderCreds: {
          UserName: generalSettings.spSuperReaderName
          Password: serviceAccountsPassword
        }
      }
    }
  }
  dependsOn: [
    generalSettings_vmSPName
  ]
}

resource vmFE_vmPublicIPName 'Microsoft.Network/publicIPAddresses@2019-09-01' = [for i in range(0, numberOfAdditionalFrontEnd): if ((numberOfAdditionalFrontEnd >= 1) && (addPublicIPAddressToEachVM == 'Yes')) {
  name: '${vmFE.vmPublicIPName}-${i}'
  location: location
  tags: {
    displayName: '${vmFE.vmPublicIPName}-${i}'
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmFE.vmPublicIPDnsName}-${i}'
    }
  }
}]

resource vmFE_vmNicName 'Microsoft.Network/networkInterfaces@2019-09-01' = [for i in range(0, numberOfAdditionalFrontEnd): if (numberOfAdditionalFrontEnd >= 1) {
  name: '${vmFE.vmNicName}-${i}'
  location: location
  tags: {
    displayName: '${vmFE.vmNicName}-${i}'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.vNetPrivateName, networkSettings.subnetSPName)
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${vmFE.vmPublicIPName}-${i}')
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_vNetPrivateName
    vmFE_vmPublicIPName
  ]
}]

resource generalSettings_vmFEName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfAdditionalFrontEnd): if (numberOfAdditionalFrontEnd >= 1) {
  name: '${generalSettings.vmFEName}-${i}'
  location: location
  tags: {
    displayName: '${generalSettings.vmFEName}-${i}'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSP.vmVmSize
    }
    osProfile: {
      computerName: '${generalSettings.vmFEName}-${i}'
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        timeZone: vmsTimeZone
        enableAutomaticUpdates: ((enableAutomaticUpdates == 'Yes') ? 'true' : 'false')
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmSP.vmImagePublisher
        offer: vmSP.vmImageOffer
        sku: vmSP.vmImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmFE.vmOSDiskName}-${i}'
        caching: 'ReadWrite'
        osType: 'Windows'
        createOption: 'FromImage'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: vmSPStorageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmFE.vmNicName}-${i}')
        }
      ]
    }
    licenseType: ((enableHybridBenefitServerLicenses == 'Yes') ? 'Windows_Server' : json('null'))
  }
  dependsOn: [
    vmFE_vmNicName
  ]
}]

resource generalSettings_vmFEName_ConfigureFEVM 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, numberOfAdditionalFrontEnd): if (numberOfAdditionalFrontEnd >= 1) {
  name: '${generalSettings.vmFEName}-${i}/ConfigureFEVM'
  location: location
  tags: {
    displayName: '${generalSettings.vmFEName}-${i}/ConfigureFEVM'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: dscConfigureFEVM.forceUpdateTag
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscConfigureFEVM.scriptFileUri
        script: dscConfigureFEVM.script
        function: dscConfigureFEVM.function
      }
      configurationArguments: {
        DNSServer: vmDC.nicPrivateIPAddress
        DomainFQDN: domainFQDN
        DCName: generalSettings.vmDCName
        SQLName: generalSettings.vmSQLName
        SQLAlias: generalSettings.sqlAlias
        SharePointVersion: sharePointVersion
      }
      privacy: {
        dataCollection: 'enable'
      }
    }
    protectedSettings: {
      configurationArguments: {
        DomainAdminCreds: {
          UserName: adminUserName
          Password: adminPassword
        }
        SPSetupCreds: {
          UserName: generalSettings.spSetupUserName
          Password: generalSettings.spSetupPassword
        }
        SPFarmCreds: {
          UserName: generalSettings.spFarmUserName
          Password: generalSettings.spFarmPassword
        }
        SPPassphraseCreds: {
          UserName: 'Passphrase'
          Password: generalSettings.spPassphrase
        }
      }
    }
  }
  dependsOn: [
    generalSettings_vmFEName
  ]
}]

resource vmDC_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-10-15-preview' = if (!(vmsAutoShutdownTime == '9999')) {
  name: vmDC.shutdownResourceName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: vmsAutoShutdownTime
    }
    timeZoneId: vmsTimeZone
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: generalSettings_vmDCName.id
  }
}

resource vmSQL_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-10-15-preview' = if (!(vmsAutoShutdownTime == '9999')) {
  name: vmSQL.shutdownResourceName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: vmsAutoShutdownTime
    }
    timeZoneId: vmsTimeZone
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: generalSettings_vmSQLName.id
  }
}

resource vmSP_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-10-15-preview' = if (!(vmsAutoShutdownTime == '9999')) {
  name: vmSP.shutdownResourceName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: vmsAutoShutdownTime
    }
    timeZoneId: vmsTimeZone
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: generalSettings_vmSPName.id
  }
}

resource vmFE_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-10-15-preview' = [for i in range(0, numberOfAdditionalFrontEnd): if ((numberOfAdditionalFrontEnd >= 1) && (!(vmsAutoShutdownTime == '9999'))) {
  name: '${vmFE.shutdownResourceName}-${i}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: vmsAutoShutdownTime
    }
    timeZoneId: vmsTimeZone
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', '${generalSettings.vmFEName}-${i}')
  }
  dependsOn: [
    generalSettings_vmFEName
  ]
}]

resource NSG_Subnet_AzureBastion 'Microsoft.Network/networkSecurityGroups@2019-09-01' = if (addAzureBastion == 'Yes') {
  name: 'NSG-Subnet-AzureBastion'
  location: location
  tags: {
    displayName: 'NSG-Subnet-AzureBastion'
  }
  properties: {
    securityRules: [
      {
        name: 'allow-443-internet'
        properties: {
          description: 'Allow 443 Internet'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
        }
      }
      {
        name: 'allow-443-gatewaymanager'
        properties: {
          description: 'Allow 443 GatewayManager '
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
        }
      }
      {
        name: 'allow-rdp-outbound'
        properties: {
          description: 'Allow RDP Outbound '
          direction: 'Outbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
        }
      }
      {
        name: 'allow-ssh-outbound'
        properties: {
          description: 'Allow SSH Outbound'
          direction: 'Outbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 121
        }
      }
      {
        name: 'allow-azurecloud-outbound'
        properties: {
          description: 'Allow AzureCloud Outbound '
          direction: 'Outbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 130
        }
      }
    ]
  }
}

resource networkSettings_vNetPrivateName_AzureBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2019-04-01' = if (addAzureBastion == 'Yes') {
  name: '${networkSettings.vNetPrivateName}/AzureBastionSubnet'
  location: location
  properties: {
    addressPrefix: azureBastion.subnetPrefix
    networkSecurityGroup: {
      id: NSG_Subnet_AzureBastion.id
    }
  }
  dependsOn: [
    networkSettings_vNetPrivateName
  ]
}

resource PublicIP_Bastion 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (addAzureBastion == 'Yes') {
  name: 'PublicIP-Bastion'
  location: location
  tags: {
    displayName: 'PublicIP-Bastion'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: azureBastion.publicIPDnsName
    }
  }
}

resource Bastion 'Microsoft.Network/bastionHosts@2019-07-01' = if (addAzureBastion == 'Yes') {
  name: 'Bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: PublicIP_Bastion.id
          }
          subnet: {
            id: networkSettings_vNetPrivateName_AzureBastionSubnet.id
          }
        }
      }
    ]
  }
}
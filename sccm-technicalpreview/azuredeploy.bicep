@minLength(2)
@maxLength(9)
@description('The prefix name of machines. ')
param prefix string

@description('Do you want to create a client for this environment?')
param createclient bool = false

@minLength(2)
@maxLength(10)
@description('The name of the administrator account of the new VM. The domain name is contoso.com ')
param adminUsername string

@minLength(8)
@description('Input must meet password complexity requirements as documented for property \'adminPassword\' in https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/virtualmachines-create-or-update')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sccm-technicalpreview/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var dscScript = 'DSC/DCConfiguration.zip'
var virtualNetworkName_var = '${toLower(prefix)}-vnet'
var domainName = 'contoso.com'
var timeZone = 'UTC'
var networkSettings = {
  virtualNetworkAddressPrefix: '10.0.0.0/16'
  subnetAddressPrefix: '10.0.0.0/24'
  virtualMachinesIPAddress: '10.0.0.'
  subnetRef: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'default')
  privateIPAllocationMethod: 'Static'
  publicIpAllocationMethod: 'Dynamic'
}
var securityGroupRuleName = 'default-allow-rdp'
var securityGroupRule = {
  priority: 1000
  sourceAddressPrefix: '*'
  protocol: 'Tcp'
  destinationPortRange: '3389'
  access: 'Allow'
  direction: 'Inbound'
  sourcePortRange: '*'
  destinationAddressPrefix: '*'
}
var vmInfoNoClient = {
  DC: {
    name: 'DC01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2s'
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
  }
  DPMP: {
    name: 'DPMP01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2s'
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
  }
}
var vmInfoWithClient = {
  DC: {
    name: 'DC01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2s'
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
  }
  DPMP: {
    name: 'DPMP01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2s'
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
  }
  Client: {
    name: 'CL01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2s'
    imageReference: {
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-10'
      sku: '20h1-pro'
      version: 'latest'
    }
  }
}
var vmrole = (createclient ? createArray('DC', 'DPMP', 'Client') : createArray('DC', 'DPMP'))
var vmInfo = (createclient ? vmInfoWithClient : vmInfoNoClient)
var siterole = [
  'PS'
]
var siteInfo = {
  PS: {
    name: 'PS01'
    disktype: 'Premium_LRS'
    size: 'Standard_B2ms'
    imageReference: {
      publisher: 'MicrosoftSQLServer'
      offer: 'SQL2019-WS2019'
      sku: 'Standard'
      version: 'latest'
    }
  }
}

resource prefix_vmInfo_vmRole_name 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, length(vmInfo)): {
  name: concat(toLower(prefix), toLower(vmInfo[vmrole[i]].name))
  location: location
  properties: {
    osProfile: {
      computerName: concat(toLower(prefix), toLower(vmInfo[vmrole[i]].name))
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    hardwareProfile: {
      vmSize: vmInfo[vmrole[i]].size
    }
    storageProfile: {
      imageReference: vmInfo[vmrole[i]].imageReference
      osDisk: {
        osType: 'Windows'
        name: '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: vmInfo[vmrole[i]].disktype
        }
        diskSizeGB: 150
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ni')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ni')
  ]
}]

resource prefix_vmInfo_vmRole_name_WorkFlow 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, length(vmInfo)): {
  name: '${toLower(prefix)}${vmInfo[vmrole[i]].name}/WorkFlow'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.21'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: uri(artifactsLocation, concat(dscScript, artifactsLocationSasToken))
      configurationFunction: '${vmrole[i]}Configuration.ps1\\Configuration'
      Properties: {
        DomainName: domainName
        DCName: concat(prefix, vmInfo.DC.name)
        DPMPName: concat(prefix, vmInfo.DPMP.name)
        PSName: concat(prefix, siteInfo.PS.name)
        ClientName: (createclient ? concat(prefix, vmInfo.Client.name) : 'Empty')
        DNSIPAddress: concat(networkSettings.virtualMachinesIPAddress, (int('0') + int('4')))
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines/', concat(toLower(prefix), vmInfo[vmrole[i]].name))
  ]
}]

resource prefix_siteInfo_siteRole_name_WorkFlow 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, length(siteInfo)): {
  name: '${toLower(prefix)}${siteInfo[siterole[i]].name}/WorkFlow'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.21'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: uri(artifactsLocation, concat(dscScript, artifactsLocationSasToken))
      configurationFunction: '${siterole[i]}Configuration.ps1\\Configuration'
      Properties: {
        DomainName: domainName
        DCName: concat(prefix, vmInfo.DC.name)
        DPMPName: concat(prefix, vmInfo.DPMP.name)
        PSName: concat(prefix, siteInfo.PS.name)
        ClientName: (createclient ? concat(prefix, vmInfo.Client.name) : 'Empty')
        DNSIPAddress: concat(networkSettings.virtualMachinesIPAddress, (int('0') + int('4')))
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines/', concat(toLower(prefix), siteInfo[siterole[i]].name))
  ]
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkSettings.virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: networkSettings.subnetAddressPrefix
        }
      }
    ]
  }
}

resource prefix_vmInfo_vmRole_name_ni 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, length(vmInfo)): {
  name: '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ni'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: networkSettings.subnetRef
          }
          privateIPAllocationMethod: networkSettings.privateIPAllocationMethod
          privateIPAddress: concat(networkSettings.virtualMachinesIPAddress, (i + int('4')))
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ip')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: prefix_nsg.id
    }
  }
  dependsOn: [
    virtualNetworkName
    resourceId('Microsoft.Network/publicIpAddresses/', '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ip')
    resourceId('Microsoft.Network/networkSecurityGroups/', '${toLower(toLower(prefix))}-nsg')
  ]
}]

resource prefix_siteInfo_siteRole_name_ni 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, length(siteInfo)): {
  name: '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ni'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: networkSettings.subnetRef
          }
          privateIPAllocationMethod: networkSettings.privateIPAllocationMethod
          privateIPAddress: concat(networkSettings.virtualMachinesIPAddress, (length(vmInfo) + (i + int('4'))))
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ip')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: prefix_nsg.id
    }
  }
  dependsOn: [
    virtualNetworkName
    resourceId('Microsoft.Network/publicIpAddresses/', '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ip')
    resourceId('Microsoft.Network/networkSecurityGroups/', '${toLower(toLower(prefix))}-nsg')
  ]
}]

resource prefix_vmInfo_vmRole_name_ip 'Microsoft.Network/publicIpAddresses@2020-05-01' = [for i in range(0, length(vmInfo)): {
  name: '${toLower(prefix)}${toLower(vmInfo[vmrole[i]].name)}-ip'
  location: location
  properties: {
    publicIPAllocationMethod: networkSettings.publicIpAllocationMethod
  }
}]

resource prefix_siteInfo_siteRole_name_ip 'Microsoft.Network/publicIpAddresses@2020-05-01' = [for i in range(0, length(siteInfo)): {
  name: '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ip'
  location: location
  properties: {
    publicIPAllocationMethod: networkSettings.publicIpAllocationMethod
  }
}]

resource prefix_nsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: '${toLower(prefix)}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: securityGroupRuleName
        properties: securityGroupRule
      }
    ]
  }
}

resource prefix_siteInfo_siteRole_name 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, length(siteInfo)): {
  name: concat(toLower(prefix), toLower(siteInfo[siterole[i]].name))
  location: location
  properties: {
    osProfile: {
      computerName: concat(toLower(prefix), toLower(siteInfo[siterole[i]].name))
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    hardwareProfile: {
      vmSize: siteInfo[siterole[i]].size
    }
    storageProfile: {
      imageReference: siteInfo[siterole[i]].imageReference
      osDisk: {
        name: '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-OsDisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: siteInfo[siterole[i]].disktype
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ni')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', '${toLower(prefix)}${toLower(siteInfo[siterole[i]].name)}-ni')
  ]
}]
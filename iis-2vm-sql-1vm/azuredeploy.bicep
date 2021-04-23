@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/iis-2vm-sql-1vm/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@minLength(2)
@maxLength(5)
@description('Prefix for the environment (2-5 characters)')
param envPrefixName string = 'cust1'

@description('SQL IaaS VM local administrator username')
param username string

@description('SQL IaaS VM local administrator password')
@secure()
param password string

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
@description('The size of the Web Server VMs Created')
param webSrvVMSize string = 'Standard_DS2'

@allowed([
  1
  2
])
@description('Number of Web Servers')
param numberOfWebSrvs int = 1

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
@description('The size of the SQL VM Created')
param sqlVMSize string = 'Standard_DS3'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('The type of the Storage Account created')
param diskType string = 'Premium_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName_var = '${envPrefixName}Vnet'
var addressPrefix = '10.0.0.0/16'
var feSubnetPrefix = '10.0.0.0/24'
var dbSubnetPrefix = '10.0.2.0/24'
var feNSGName_var = 'feNsg'
var dbNSGName_var = 'dbNsg'
var sqlSrvDBName = '${envPrefixName}sqlSrv14'
var sqlVmSize_var = sqlVMSize
var sqlSrvDBNicName_var = '${sqlSrvDBName}Nic'
var sqlSvrDBSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'DBSubnetName')
var sqlPublicIP_var = '${envPrefixName}SqlPip'
var sqlPublicIPRef = sqlPublicIP.id
var sqlImagePublisher = 'MicrosoftSQLServer'
var sqlImageOffer = 'SQL2014SP2-WS2012R2'
var sqlImageSku = 'Standard'
var webSrvName_var = '${envPrefixName}webSrv'
var webSrvVMSize_var = webSrvVMSize
var webSrvNicName_var = '${webSrvName_var}Nic'
var webSrvSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'FESubnetName')
var webSrvPublicIP_var = '${envPrefixName}websrvpip'
var webSrvAvailabilitySetName_var = '${envPrefixName}webSrvAS'
var webSrvNumbOfInstances = numberOfWebSrvs
var webSrvDnsNameforLBIP = '${toLower(webSrvName_var)}lb'
var webLbName_var = '${webSrvName_var}lb'
var webLblb_PIP_Id = webSrvPublicIP.id
var webLbId = webLbName.id
var frontEndIPConfigID = '${webLbId}/frontendIPConfigurations/LoadBalancerFrontEnd'
var lbPoolID = '${webLbId}/backendAddressPools/BackendPool1'
var lbProbeID = '${webLbId}/probes/tcpProbe'
var vmExtensionName = 'dscExtension'
var modulesUrl = '${artifactsLocation}scripts/WebServerConfig.ps1.zip${artifactsLocationSasToken}'
var configurationFunction = 'WebServerConfig.ps1\\WebServerConfig'

resource feNSGName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: feNSGName_var
  location: location
  tags: {
    displayName: 'FrontEndNSG'
  }
  properties: {
    securityRules: [
      {
        name: 'rdp_rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'web_rule'
        properties: {
          description: 'Allow WEB'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource dbNSGName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: dbNSGName_var
  location: location
  tags: {
    displayName: 'BackEndNSG'
  }
  properties: {
    securityRules: [
      {
        name: 'Allow_FE'
        properties: {
          description: 'Allow FE Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'rdp_rule'
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
      {
        name: 'Block_FE'
        properties: {
          description: 'Block App Subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 121
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_Internet'
        properties: {
          description: 'Block Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
        }
      }
    ]
  }
}

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
        name: 'FESubnetName'
        properties: {
          addressPrefix: feSubnetPrefix
          networkSecurityGroup: {
            id: feNSGName.id
          }
        }
      }
      {
        name: 'DBSubnetName'
        properties: {
          addressPrefix: dbSubnetPrefix
          networkSecurityGroup: {
            id: dbNSGName.id
          }
        }
      }
    ]
  }
}

resource sqlPublicIP 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: sqlPublicIP_var
  location: location
  tags: {
    displayName: 'SqlPIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}

resource sqlSrvDBNicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: sqlSrvDBNicName_var
  location: location
  tags: {
    displayName: 'SQLSrvDBNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: sqlSvrDBSubnetRef
          }
          publicIPAddress: {
            id: sqlPublicIPRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource envPrefixName_sqlSrv14 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: '${envPrefixName}sqlSrv14'
  location: location
  tags: {
    displayName: 'SQL-Svr-DB'
  }
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize_var
    }
    osProfile: {
      computerName: sqlSrvDBName
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: sqlImagePublisher
        offer: sqlImageOffer
        sku: sqlImageSku
        version: 'latest'
      }
      osDisk: {
        name: '${sqlSrvDBName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sqlSrvDBNicName.id
        }
      ]
    }
  }
  dependsOn: [
    sqlPublicIP
  ]
}

resource webSrvAvailabilitySetName 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  location: location
  name: webSrvAvailabilitySetName_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  tags: {
    displayName: 'WebSrvAvailabilitySet'
  }
  sku: {
    name: 'Aligned'
  }
}

resource webSrvPublicIP 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: webSrvPublicIP_var
  location: location
  tags: {
    displayName: 'WebSrvPIP for LB'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: webSrvDnsNameforLBIP
    }
  }
}

resource webLbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: webLbName_var
  location: location
  tags: {
    displayName: 'Web LB'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: webLblb_PIP_Id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'RDP-VM1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50002
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource webSrvNicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, webSrvNumbOfInstances): {
  name: concat(webSrvNicName_var, i)
  location: location
  tags: {
    displayName: 'WebSrvNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: webSrvSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${webLbId}/backendAddressPools/BackendPool1'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${webLbId}/inboundNatRules/RDP-VM${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    webLbName
  ]
}]

resource webSrvName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, webSrvNumbOfInstances): {
  name: concat(webSrvName_var, i)
  location: location
  tags: {
    displayName: 'WebSrv'
  }
  properties: {
    availabilitySet: {
      id: webSrvAvailabilitySetName.id
    }
    hardwareProfile: {
      vmSize: webSrvVMSize_var
    }
    osProfile: {
      computerName: concat(webSrvName_var, i)
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${webSrvName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(webSrvNicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${webSrvNicName_var}${i}'
    webSrvAvailabilitySetName
  ]
}]

resource webSrvName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, webSrvNumbOfInstances): {
  name: '${webSrvName_var}${i}/${vmExtensionName}'
  location: location
  tags: {
    displayName: 'VM Extensions'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: modulesUrl
      SasToken: ''
      ConfigurationFunction: configurationFunction
      wmfVersion: '4.0'
      Properties: {}
    }
    protectedSettings: {}
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${webSrvName_var}${i}'
  ]
}]
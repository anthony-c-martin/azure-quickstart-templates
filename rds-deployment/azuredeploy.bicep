@description('Unique gateway public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'. For example johndns1 will result the final RDWEB access url like https://johndns1.westus.cloudapp.azure.com/RDWeb')
param gwdnsLabelPrefix string

@description('The name of gateway PublicIPAddress object')
param gwpublicIPAddressName string = 'gwpip'

@description('The name of the AD domain. For example contoso.com')
param adDomainName string = 'contoso.com'

@description('The name of the administrator of the new VM and the domain. Exclusion list: \'administrator\'. For example johnadmin')
param adminUsername string = 'vmadmin'

@description('The password for the administrator account of the new VM and the domain')
@secure()
param adminPassword string = 'Subscription#${subscription().subscriptionId}'

@allowed([
  '2012-R2-Datacenter'
  '2016-Datacenter'
])
@description('Windows server SKU')
param imageSKU string = '2016-Datacenter'

@description('Number of RemoteDesktopSessionHosts')
param numberOfRdshInstances int = 1

@allowed([
  'Standard_A1_v2'
  'Standard_A2_v2'
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_A2m_v2'
  'Standard_A4m_v2'
  'Standard_A8m_v2'
  'Standard_D2_v3'
  'Standard_D4_v3'
  'Standard_D8_v3'
  'Standard_D16_v3'
  'Standard_D32_v3'
  'Standard_D48_v3'
  'Standard_D64_v3'
])
@description('The size of the RDSH VMs')
param rdshVmSize string = 'Standard_D4_v3'

@description('Location for all resources.')
param location string = resourceGroup().location

var adAssetLocation = 'https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/ad-non-ha'
var adVMSize = 'Standard_A1'
var adVnetName_var = 'ADVNET${resourceGroup().name}'
var adSubnetName = 'ADStaticSubnet${resourceGroup().name}'
var staticSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', adVnetName_var, adSubnetName)
var adTemplateURL = '${adAssetLocation}/adVmTemplate.json'
var adStorageName = toLower('adsa${uniqueString(resourceGroup().id)}')
var adVmDeployment_var = 'CreateAdVms'
var adVmDeploymentId = 'Microsoft.Resources/deployments/${adVmDeployment_var}'
var deployPrimaryAdTemplateURL = '${adAssetLocation}/deployPrimaryAD.json'
var deployPrimaryAd_var = 'DeployPrimaryAd'
var deployPrimaryAdID = 'Microsoft.Resources/deployments/${deployPrimaryAd_var}'
var adPDCVMName = 'advm'
var vnetwithDNSTemplateURL = '${adAssetLocation}/vnet-with-dns-server.json'
var updateVNetDNS1_var = 'updateVNetDNS'
var publicLBName_var = 'ADPLB${resourceGroup().name}'
var publicIPAddressID = publicIPAddressName.id
var lbFE = 'ADLBFE'
var rdpNAT = 'ADRDPNAT'
var publiclbID = publiclbName.id
var publiclbFEConfigID = '${publiclbID}/frontendIPConfigurations/${lbFE}'
var rdpPort = 3389
var adRDPNATRuleID = '${publiclbID}/inboundNatRules/${rdpNAT}'
var adNICName = 'ADNic${resourceGroup().name}'
var lbBE = 'ADLBBE'
var gwLBName_var = 'GWPLB${resourceGroup().name}'
var publicIPAddressName_var = toLower('adpip${uniqueString(resourceGroup().id)}')
var gwIPAddressID = gwpublicIPAddressName_resource.id
var gwlbFE = 'GWLBFE'
var gwlbID = gwlbName.id
var gwlbFEConfigID = '${gwlbID}/frontendIPConfigurations/${gwlbFE}'
var gwlbBE = 'GWLBBE'
var gwBEAddressPoolID = '${gwlbID}/backendAddressPools/${gwlbBE}'
var dnsLabelPrefix = toLower('adns${resourceGroup().name}')
var storageAccountName_var = toLower('rdsa${uniqueString(resourceGroup().id)}')
var storageAccountType = 'Standard_LRS'
var uniqueStorageAccountContainerName = toLower('sc${uniqueString(resourceGroup().id)}')
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var vnetAddressRange = '10.0.0.0/16'
var subnetAddressRange = '10.0.0.0/24'
var dnsServerPrivateIp = '10.0.0.4'
var subnet_id = '${adVnetName.id}/subnets/${adSubnetName}'
var assetLocation = 'https://raw.githubusercontent.com/Azure/azure-QuickStart-Templates/master/rds-deployment/'
var nsgName_var = 'RDSNsg'
var nsgID = nsgName.id
var subnets = [
  {
    name: adSubnetName
    properties: {
      addressPrefix: subnetAddressRange
      networkSecurityGroup: {
        id: nsgID
      }
    }
  }
]

resource nsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'rule1'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource adVnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: adVnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressRange
      ]
    }
    subnets: [
      {
        name: adSubnetName
        properties: {
          addressPrefix: subnetAddressRange
          networkSecurityGroup: {
            id: nsgID
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgID
  ]
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
  dependsOn: [
    adVnetName
  ]
}

resource gwpublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gwpublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: gwdnsLabelPrefix
    }
  }
  dependsOn: [
    deployPrimaryAdID
  ]
}

resource gw_availabilityset 'Microsoft.Compute/availabilitySets@2015-06-15' = {
  name: 'gw-availabilityset'
  location: location
}

resource cb_availabilityset 'Microsoft.Compute/availabilitySets@2015-06-15' = {
  name: 'cb-availabilityset'
  location: location
}

resource rdsh_availabilityset 'Microsoft.Compute/availabilitySets@2015-06-15' = {
  name: 'rdsh-availabilityset'
  location: location
}

resource publiclbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: publicLBName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFE
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBE
      }
    ]
    inboundNatRules: [
      {
        name: rdpNAT
        properties: {
          frontendIPConfiguration: {
            id: publiclbFEConfigID
          }
          protocol: 'Tcp'
          frontendPort: rdpPort
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressID
  ]
}

resource gwlbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: gwLBName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: gwlbFE
        properties: {
          publicIPAddress: {
            id: gwIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: gwlbBE
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule01'
        properties: {
          frontendIPConfiguration: {
            id: gwlbFEConfigID
          }
          backendAddressPool: {
            id: gwBEAddressPoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: '${gwlbID}/probes/tcpProbe'
          }
        }
      }
      {
        name: 'LBRule02'
        properties: {
          frontendIPConfiguration: {
            id: gwlbFEConfigID
          }
          backendAddressPool: {
            id: gwBEAddressPoolID
          }
          protocol: 'Udp'
          frontendPort: 3391
          backendPort: 3391
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: '${gwlbID}/probes/tcpProbe01'
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'tcpProbe01'
        properties: {
          protocol: 'Tcp'
          port: 3391
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'rdp'
        properties: {
          frontendIPConfiguration: {
            id: gwlbFEConfigID
          }
          protocol: 'Tcp'
          frontendPort: 3389
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    gwIPAddressID
  ]
}

module adVmDeployment '?' /*TODO: replace with correct path to [variables('adTemplateURL')]*/ = {
  name: adVmDeployment_var
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    adRDPNATRuleID: adRDPNATRuleID
    storageAccount: adStorageName
    subnetResourceId: staticSubnetID
    primaryAdIpAddress: dnsServerPrivateIp
    storageAccountType: storageAccountType
    vmName: adPDCVMName
    vmSize: adVMSize
    adDNicName: adNICName
  }
  dependsOn: [
    publiclbID
  ]
}

module deployPrimaryAd '?' /*TODO: replace with correct path to [variables('deployPrimaryAdTemplateURL')]*/ = {
  name: deployPrimaryAd_var
  params: {
    primaryADName: adPDCVMName
    domainName: adDomainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: adAssetLocation
  }
  dependsOn: [
    adVmDeploymentId
  ]
}

module updateVNetDNS1 '?' /*TODO: replace with correct path to [variables('vnetwithDNSTemplateURL')]*/ = {
  name: updateVNetDNS1_var
  params: {
    virtualNetworkName: adVnetName_var
    virtualNetworkAddressRange: vnetAddressRange
    subnets: subnets
    dnsServerAddress: [
      dnsServerPrivateIp
    ]
  }
  dependsOn: [
    deployPrimaryAdID
  ]
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource gw_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'gw-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: gwBEAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${gwlbID}/inboundNatRules/rdp'
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    gwlbID
    adVmDeploymentId
  ]
}

resource cb_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'cb-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    publiclbID
    adVmDeploymentId
  ]
}

resource rdsh_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    publiclbID
    adVmDeploymentId
  ]
}]

resource gw_vm 'Microsoft.Compute/virtualMachines@2015-06-15' = {
  name: 'gw-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2'
    }
    availabilitySet: {
      id: gw_availabilityset.id
    }
    osProfile: {
      computerName: 'gateway'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        vhd: {
          uri: '${reference('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2016-01-01').primaryEndpoints.blob}${uniqueStorageAccountContainerName}/gw-vm-os-disk.vhd'
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: gw_nic.id
        }
      ]
    }
  }
  dependsOn: [
    deployPrimaryAdID
    storageAccountName
  ]
}

resource gw_vm_gateway 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: gw_vm
  name: 'gateway'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${assetLocation}/Configuration.zip'
      configurationFunction: 'Configuration.ps1\\Gateway'
      Properties: {
        DomainName: adDomainName
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
}

resource rdsh 'Microsoft.Compute/virtualMachines@2015-06-15' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: {
      id: rdsh_availabilityset.id
    }
    osProfile: {
      computerName: 'rdsh-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        vhd: {
          uri: '${reference('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2016-01-01').primaryEndpoints.blob}${uniqueStorageAccountContainerName}/rdsh-${i}-os-disk.vhd'
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'rdsh-${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    deployPrimaryAdID
    storageAccountName
    'Microsoft.Network/networkInterfaces/rdsh-${i}-nic'
  ]
}]

resource rdsh_sessionhost 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}/sessionhost'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: '${assetLocation}/Configuration.zip'
      ConfigurationFunction: 'Configuration.ps1\\SessionHost'
      Properties: {
        DomainName: adDomainName
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
    resourceId('Microsoft.Compute/virtualMachines', 'rdsh-${i}')
  ]
}]

resource cb_vm 'Microsoft.Compute/virtualMachines@2015-06-15' = {
  name: 'cb-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2'
    }
    availabilitySet: {
      id: cb_availabilityset.id
    }
    osProfile: {
      computerName: 'broker'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        vhd: {
          uri: '${reference('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2016-01-01').primaryEndpoints.blob}${uniqueStorageAccountContainerName}/cb-vm-os-disk.vhd'
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cb_nic.id
        }
      ]
    }
  }
  dependsOn: [
    deployPrimaryAdID
    storageAccountName

    rdsh
  ]
}

resource cb_vm_rdsdeployment 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: cb_vm
  name: 'rdsdeployment'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    protectedSettings: {
      Items: {
        adminPassword: adminPassword
      }
    }
    publisher: 'Microsoft.Powershell'
    settings: {
      modulesUrl: '${assetLocation}/Configuration.zip'
      configurationFunction: 'Configuration.ps1\\RDSDeployment'
      Properties: {
        adminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
        connectionBroker: 'broker.${adDomainName}'
        domainName: adDomainName
        externalfqdn: reference(gwpublicIPAddressName).dnsSettings.fqdn
        numberOfRdshInstances: numberOfRdshInstances
        sessionHostNamingPrefix: 'rdsh-'
        webAccessServer: 'gateway.${adDomainName}'
      }
    }
    type: 'DSC'
    typeHandlerVersion: '2.11'
  }
  dependsOn: [
    gw_vm_gateway
    rdsh
  ]
}
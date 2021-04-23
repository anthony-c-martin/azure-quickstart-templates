@description('Username for the virtual Machines')
param adminUsername string

@minLength(12)
@description('Password for Barracuda WAF Admin Interface and Backend Web Servers(Min Length: 12)')
@secure()
param adminPassword string

@description('Number of backend Web servers to be deployed')
param webVmCount int = 2

@minLength(7)
@description('Enter Public IP CIDR to allow for accessing the deployment.Enter in 0.0.0.0/0 format. You can always modify these later in NSG Settings')
param remoteAllowedCIDR string = '0.0.0.0/0'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/barracuda-waf-iis/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.Leave blank if unsure')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var bwafVmSize = 'Standard_D2_v2'
var webVmSize = 'Standard_D2_v2'
var storageAccountType = 'Standard_GRS'
var bwafStorageAccountName_var = 'bwafstorage${uniqueString(resourceGroup().id)}'
var webStorageAccountName_var = 'webstorage${uniqueString(resourceGroup().id)}'
var diagStorageAccountName_var = 'diagstorage${uniqueString(resourceGroup().id)}'
var virtualNetworkName_var = 'bwaf-vnet'
var webNSGName_var = 'web-NSG'
var bwafNSGName_var = 'bwaf-NSG'
var bwafSubnetName = 'bwaf-subnet'
var webSubnetName = 'web-subnet'
var lbIPAddressName_var = 'lb-pip'
var lbDnsLabel = 'lbpip${uniqueString(resourceGroup().id)}'
var loadBalancerName_var = 'web-rdp-lb'
var loadBalancerID = loadBalancerName.id
var loadBalancerIPID = lbIPAddressName.id
var frontEndIPConfigID = '${loadBalancerName.id}/frontendIPConfigurations/loadBalancerFrontEnd'
var bwafAvailSetName_var = 'bwaf-as'
var bwafVmName_var = 'bwaf-vm'
var bwafVmIPAddressName_var = 'bwaf-pip'
var bwafVmDnsLabel = 'bwafpip${uniqueString(resourceGroup().id)}'
var bwafVmNicName_var = '${bwafVmName_var}-nic'
var webAvailSetName_var = 'web-as'
var webVmName = 'web-vm'
var webVmNicName = '${webVmName}-nic'
var webVmSku = '2012-R2-Datacenter'
var webVmPublisher = 'MicrosoftWindowsServer'
var webVmOffer = 'WindowsServer'
var dscfilename = 'webserverconfig.zip'
var webVmExtensionFunction = 'webServerConfig.ps1\\WebServerConfig'
var vmStorageAccountContainerName = 'vhds'
var OSDiskName = 'OSDisk'
var barracudaNetworksTags = {
  type: 'object'
  provider: '3285C15D-A16F-479C-8886-67042BCB03A9'
}
var quickstartTags = {
  type: 'object'
  name: 'barracuda-waf-iis'
}

resource bwafStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: bwafStorageAccountName_var
  location: location
  tags: {
    displayName: 'BWAF VM Storage Account'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource webStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: webStorageAccountName_var
  location: location
  tags: {
    displayName: 'Web VM Storage Account'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: diagStorageAccountName_var
  location: location
  tags: {
    displayName: 'Diagnostics Storage Account'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource bwafNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: bwafNSGName_var
  location: location
  tags: {
    displayName: 'BWAF NSG'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'HTTP-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTPS-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AdminPortal-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8000'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource webNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: webNSGName_var
  location: location
  tags: {
    displayName: 'Web NSG'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'RDP-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource bwafVmIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: bwafVmIPAddressName_var
  location: location
  tags: {
    displayName: 'BWAF Public IP'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: bwafVmDnsLabel
    }
  }
}

resource lbIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: lbIPAddressName_var
  location: location
  tags: {
    displayName: 'LB Public IP'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: lbDnsLabel
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'Bwaf Virtual Network'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: bwafSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: bwafNSGName.id
          }
        }
      }
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: webNSGName.id
          }
        }
      }
    ]
  }
}

resource webAvailSetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: webAvailSetName_var
  location: location
  tags: {
    displayName: 'Web Avail Set'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {}
}

resource bwafAvailSetName 'Microsoft.Compute/availabilitySets@2015-06-15' = {
  name: bwafAvailSetName_var
  location: location
  tags: {
    displayName: 'BWAF Avail Set'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {}
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancerName_var
  location: location
  tags: {
    displayName: 'Web RDP Load Balancer'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: loadBalancerIPID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd'
      }
    ]
  }
}

resource loadBalancerName_RDPVM_1 'Microsoft.Network/loadBalancers/inboundNatRules@2016-03-30' = [for i in range(0, webVmCount): {
  name: '${loadBalancerName_var}/RDPVM${(i + 1)}'
  location: location
  tags: {
    displayName: 'LB RDP NAT rules'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    frontendIPConfiguration: {
      id: frontEndIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: (i + 5001)
    backendPort: 3389
    enableFloatingIP: false
  }
  dependsOn: [
    loadBalancerName
  ]
}]

resource webVmNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, webVmCount): {
  name: concat(webVmNicName, (i + 1))
  location: location
  tags: {
    displayName: 'Web VM NICs'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetworkName.id}/subnets/${webSubnetName}'
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadBalancerID}/backendAddressPools/LoadBalancerBackend'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${loadBalancerID}/inboundNatRules/RDPVM${(i + 1)}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    'Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatRules/RDPVM${(i + 1)}'
  ]
}]

resource bwafVmNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: bwafVmNicName_var
  location: location
  tags: {
    displayName: 'BWAF VM NIC'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: concat(bwafVmIPAddressName.id)
          }
          subnet: {
            id: '${virtualNetworkName.id}/subnets/${bwafSubnetName}'
          }
        }
      }
    ]
  }
}

resource webVmName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, webVmCount): {
  name: concat(webVmName, (i + 1))
  location: location
  tags: {
    displayName: 'Web VMs'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    availabilitySet: {
      id: webAvailSetName.id
    }
    hardwareProfile: {
      vmSize: webVmSize
    }
    osProfile: {
      computerName: 'webserver${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: webVmPublisher
        offer: webVmOffer
        sku: webVmSku
        version: 'latest'
      }
      osDisk: {
        name: '${webVmName}${(i + 1)}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(webVmNicName, (i + 1)))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: diagStorageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    webStorageAccountName
    'Microsoft.Network/networkInterfaces/${webVmNicName}${(i + 1)}'
    webAvailSetName
  ]
}]

resource webVmName_1_webVmName_1_web_dsc 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, webVmCount): {
  name: '${webVmName}${(i + 1)}/${webVmName}${(i + 1)}-web-dsc'
  location: location
  tags: {
    displayName: 'Web VM Extensions'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${artifactsLocation}scripts/${dscfilename}${artifactsLocationSasToken}'
      configurationFunction: webVmExtensionFunction
      wmfVersion: '4.0'
      Properties: {}
    }
    protectedSettings: {}
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${webVmName}${(i + 1)}'
  ]
}]

resource bwafVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: bwafVmName_var
  location: location
  tags: {
    displayName: 'BWAF VM'
    quickstartName: quickstartTags.name
    provider: barracudaNetworksTags.provider
  }
  plan: {
    name: 'hourly'
    publisher: 'barracudanetworks'
    product: 'waf'
  }
  properties: {
    osProfile: {
      computerName: 'bwafserver'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    hardwareProfile: {
      vmSize: bwafVmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'barracudanetworks'
        offer: 'waf'
        sku: 'hourly'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        name: '${bwafVmName_var}_OSDisk'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: bwafVmNicName.id
        }
      ]
    }
    availabilitySet: {
      id: bwafAvailSetName.id
    }
  }
  dependsOn: [
    bwafStorageAccountName
  ]
}

output loadBalancerIP string = lbIPAddressName.properties.ipAddress
output bwafIP string = bwafVmIPAddressName.properties.ipAddress
output loadBalancerFqdn string = lbIPAddressName.properties.dnsSettings.fqdn
output bwafFqdn string = bwafVmIPAddressName.properties.dnsSettings.fqdn
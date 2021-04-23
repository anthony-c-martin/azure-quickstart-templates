@description('Username for the Virtual Machines')
param adminUsername string

@description('Number of Web servers to be deployed')
param webTierVmCount int = 2

@description('Number of App servers to be deployed')
param appTierVmCount int = 2

@description('Number of Database servers to be deployed')
param databaseTierVmCount int = 2

@minLength(7)
@description('Enter Public IP CIDR to allow for accessing the deployment.Enter in 0.0.0.0/0 format, you can always modify these later in NSG Settings')
param remoteAllowedCIDR string = '0.0.0.0/0'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vmSize = 'Standard_D2_v2'
var vmStorageAccountType = 'Standard_GRS'
var vmStorageAccountName = '${uniqueString(resourceGroup().id)}storage'
var diagStorageAccountName_var = '${uniqueString(resourceGroup().id)}diagstorage'
var virtualNetworkName_var = 'RedHat3Tier-vnet'
var webTierSubnetName = 'web-tier-subnet'
var appTierSubnetName = 'app-tier-subnet'
var databaseTierSubnetName = 'database-tier-subnet'
var jumpSubnetName = 'jump-subnet'
var webNSGName_var = 'web-tier-nsg'
var appNSGName_var = 'app-tier-nsg'
var databaseNSGName_var = 'database-tier-nsg'
var jumpNSGName_var = 'jump-nsg'
var webLoadBalancerName_var = 'web-lb'
var weblbIPAddressName_var = 'web-lb-pip'
var weblbDnsLabel = 'weblb${uniqueString(resourceGroup().id)}'
var webLoadBalancerIPID = weblbIPAddressName.id
var webFrontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', webLoadBalancerName_var, 'loadBalancerFrontEnd')
var weblbBackendPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', webLoadBalancerName_var, 'loadBalancerBackend')
var weblbProbeHttpID = resourceId('Microsoft.Network/loadBalancers/probes', webLoadBalancerName_var, 'weblbProbeHttp')
var weblbProbeHttpsID = resourceId('Microsoft.Network/loadBalancers/probes', webLoadBalancerName_var, 'weblbProbeHttps')
var internalLoadBalancerName_var = 'internal-lb'
var internalFrontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', internalLoadBalancerName_var, 'loadBalancerFrontEnd')
var internallbBackendPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', internalLoadBalancerName_var, 'loadBalancerBackend')
var internallbProbeSSHID = resourceId('Microsoft.Network/loadBalancers/probes', internalLoadBalancerName_var, 'internallbProbeSSH')
var jumpIPAddressName_var = 'jump-pip'
var jumpDnsLabel = 'jump${uniqueString(resourceGroup().id)}'
var availSetName = 'avail-set-'
var webTierVmNicName = '${webTierVmName}-nic-'
var appTierVmNicName = '${appTierVmName}-nic-'
var databaseTierVmNicName = '${databaseTierVmName}-nic-'
var jumpVmNicName_var = '${jumpVmName_var}-nic'
var redHatsku = '7.3'
var Publisher = 'RedHat'
var Offer = 'RHEL'
var webTierVmName = 'web-tier-vm'
var appTierVmName = 'app-tier-vm'
var databaseTierVmName = 'database-tier-vm'
var jumpVmName_var = 'jump-vm'
var redHatTags = {
  type: 'object'
  provider: '9d2c71fc-96ba-4b4a-93b3-14def5bc96fc'
}
var quickstartTags = {
  type: 'object'
  name: 'rhel-3tier-iaas'
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource vmStorageAccountName_1 'Microsoft.Storage/storageAccounts@2016-01-01' = [for i in range(0, 4): {
  name: concat(vmStorageAccountName, (i + 1))
  location: location
  tags: {
    displayName: 'VM Storage Accounts'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  sku: {
    name: vmStorageAccountType
  }
  kind: 'Storage'
  properties: {}
}]

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: diagStorageAccountName_var
  location: location
  tags: {
    displayName: 'Diagnostics Storage Account'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource webNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: webNSGName_var
  location: location
  tags: {
    displayName: 'Web NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
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
          destinationAddressPrefix: '10.0.1.0/24'
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
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: appNSGName_var
  location: location
  tags: {
    displayName: 'App NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    securityRules: []
  }
}

resource databaseNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: databaseNSGName_var
  location: location
  tags: {
    displayName: 'Database NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    securityRules: []
  }
}

resource jumpNSGName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: jumpNSGName_var
  location: location
  tags: {
    displayName: 'Jump NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'SSH-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '10.0.0.128/25'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource jumpIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: jumpIPAddressName_var
  location: location
  tags: {
    displayName: 'Jump VM Public IP'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: jumpDnsLabel
    }
    idleTimeoutInMinutes: 4
  }
}

resource weblbIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: weblbIPAddressName_var
  location: location
  tags: {
    displayName: 'Web LB Public IP'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: weblbDnsLabel
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'Virtual Network'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: webTierSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: webNSGName.id
          }
        }
      }
      {
        name: appTierSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: appNSGName.id
          }
        }
      }
      {
        name: databaseTierSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: databaseNSGName.id
          }
        }
      }
      {
        name: jumpSubnetName
        properties: {
          addressPrefix: '10.0.0.128/25'
          networkSecurityGroup: {
            id: jumpNSGName.id
          }
        }
      }
    ]
  }
}

resource availSetName_1 'Microsoft.Compute/availabilitySets@2017-12-01' = [for i in range(0, 3): {
  name: concat(availSetName, (i + 1))
  location: location
  tags: {
    displayName: 'Availability Sets'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}]

resource webLoadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: webLoadBalancerName_var
  location: location
  tags: {
    displayName: 'External Load Balancer'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: webLoadBalancerIPID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackend'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRuleForlb80IP'
        properties: {
          frontendIPConfiguration: {
            id: webFrontEndIPConfigID
          }
          backendAddressPool: {
            id: weblbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 5
          enableFloatingIP: false
          probe: {
            id: weblbProbeHttpID
          }
        }
      }
      {
        name: 'LBRuleForlb443IP'
        properties: {
          frontendIPConfiguration: {
            id: webFrontEndIPConfigID
          }
          backendAddressPool: {
            id: weblbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          idleTimeoutInMinutes: 5
          enableFloatingIP: false
          probe: {
            id: weblbProbeHttpsID
          }
        }
      }
    ]
    probes: [
      {
        name: 'weblbProbeHttp'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'weblbProbeHttps'
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource internalLoadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: internalLoadBalancerName_var
  location: location
  tags: {
    displayName: 'Internal Load Balancer'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, webTierSubnetName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd'
      }
    ]
    loadBalancingRules: [
      {
        name: 'internallbruleSSH'
        properties: {
          frontendIPConfiguration: {
            id: internalFrontEndIPConfigID
          }
          backendAddressPool: {
            id: internallbBackendPoolID
          }
          probe: {
            id: internallbProbeSSHID
          }
          protocol: 'Tcp'
          frontendPort: 22
          backendPort: 22
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        name: 'internallbProbeSSH'
        properties: {
          protocol: 'Tcp'
          port: 22
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource webTierVmNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, webTierVmCount): {
  name: concat(webTierVmNicName, (i + 1))
  location: location
  tags: {
    displayName: 'Web Tier VM NICs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, webTierSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: weblbBackendPoolID
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    webLoadBalancerName
  ]
}]

resource appTierVmNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, appTierVmCount): {
  name: concat(appTierVmNicName, (i + 1))
  location: location
  tags: {
    displayName: 'App Tier VM NICs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, appTierSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: internallbBackendPoolID
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    internalLoadBalancerName
  ]
}]

resource databaseTierVmNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, databaseTierVmCount): {
  name: concat(databaseTierVmNicName, (i + 1))
  location: location
  tags: {
    displayName: 'Database Tier VM NICs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, databaseTierSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}]

resource jumpVmNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: jumpVmNicName_var
  location: location
  tags: {
    displayName: 'Jump VM NIC'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jumpIPAddressName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, jumpSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource webTierVmName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, webTierVmCount): {
  name: '${webTierVmName}-${(i + 1)}'
  location: location
  tags: {
    displayName: 'Web Tier VMs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availSetName}1')
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'webserver${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: Publisher
        offer: Offer
        sku: redHatsku
        version: 'latest'
      }
      osDisk: {
        name: '${webTierVmName}-${(i + 1)}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(webTierVmNicName, (i + 1)))
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
    'Microsoft.Storage/storageAccounts/${vmStorageAccountName}1'
    'Microsoft.Network/networkInterfaces/${webTierVmNicName}${(i + 1)}'
    'Microsoft.Compute/availabilitySets/${availSetName}1'
  ]
}]

resource appTierVmName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, appTierVmCount): {
  name: '${appTierVmName}-${(i + 1)}'
  location: location
  tags: {
    displayName: 'App Tier VMs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availSetName}2')
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'appserver${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: Publisher
        offer: Offer
        sku: redHatsku
        version: 'latest'
      }
      osDisk: {
        name: '${appTierVmName}-${(i + 1)}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(appTierVmNicName, (i + 1)))
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
    'Microsoft.Storage/storageAccounts/${vmStorageAccountName}2'
    'Microsoft.Network/networkInterfaces/${appTierVmNicName}${(i + 1)}'
    'Microsoft.Compute/availabilitySets/${availSetName}2'
  ]
}]

resource databaseTierVmName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, databaseTierVmCount): {
  name: '${databaseTierVmName}-${(i + 1)}'
  location: location
  tags: {
    displayName: 'Database Tier VMs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availSetName}3')
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'databaseserver${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: Publisher
        offer: Offer
        sku: redHatsku
        version: 'latest'
      }
      osDisk: {
        name: '${databaseTierVmName}-${(i + 1)}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(databaseTierVmNicName, (i + 1)))
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
    'Microsoft.Storage/storageAccounts/${vmStorageAccountName}3'
    'Microsoft.Network/networkInterfaces/${databaseTierVmNicName}${(i + 1)}'
    'Microsoft.Compute/availabilitySets/${availSetName}3'
  ]
}]

resource jumpVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jumpVmName_var
  location: location
  tags: {
    displayName: 'Jump VM'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'jumpvm'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: Publisher
        offer: Offer
        sku: redHatsku
        version: 'latest'
      }
      osDisk: {
        name: '${jumpVmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpVmNicName.id
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
    'Microsoft.Storage/storageAccounts/${vmStorageAccountName}4'
  ]
}

output webLoadBalancerIP string = weblbIPAddressName.properties.ipAddress
output webLoadBalancerFqdn string = weblbIPAddressName.properties.dnsSettings.fqdn
output jumpVMIP string = jumpIPAddressName.properties.ipAddress
output jumpVMFqdn string = jumpIPAddressName.properties.dnsSettings.fqdn
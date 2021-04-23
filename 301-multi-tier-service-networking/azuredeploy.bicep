@description('Unique DNS Name for the Storage Account where the DB Virtual Machine disks will be placed.')
param newDBStorageAccountName string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Prefix for the name of Application servers')
param appVmNamePrefix string = 'MultiTierApp'

@description('Prefix for the name of Database servers')
param dbVmNamePrefix string = 'MultiTierDB'

@description('Size of the VM')
param vmSize string = 'Standard_D2_v2'

@allowed([
  'Dynamic'
  'Static'
])
@description('Type of public IP address')
param publicIPAddressType string = 'Dynamic'

@description('Prefix for the name of Database servers')
param appServersPublicIPPrefix string = 'appserverpubIP'

@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
])
@description('Sku Name')
param skuName string = 'Standard_Medium'

@description('Number of instances of the Application Gateway')
param appGatewayCapacity int = 2

@description('Internal Load Balancer name')
param multitierILB string = 'ILBforSql'

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
  '2016-Datacenter'
  '2019-Datacenter'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter, 2016-Datacenter, 2019-Datacenter.')
param windowsOSVersion string = '2019-Datacenter'

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var storageAccountType = 'Standard_LRS'
var VNetName_var = 'multiTierVNet'
var FESubnetName = 'FrontendSubnet'
var AppSubnetName = 'AppSubnet'
var BESubnetName = 'BackendSubnet'
var VNetAddressPrefix = '10.1.0.0/16'
var FrontendPrefix = '10.1.0.0/24'
var AppPrefix = '10.1.1.0/24'
var BackendPrefix = '10.1.2.0/24'
var appAvailabilitySetName_var = 'appAvSet'
var AppServerIP1 = '10.1.1.4'
var AppServerIP2 = '10.1.1.5'
var FeNsgname_var = 'FrontendNSG'
var AppNsgname_var = 'AppNSG'
var BeNsgname_var = 'BackendNSG'
var appGatewayName_var = 'multitierAppGateway'
var appGatewayPubIPName_var = 'multitierAppGatewayIP'
var ILBIP = '10.1.2.100'
var appNicName_var = 'appNic'
var dbNicName_var = 'dbNic'
var appScaleCount = 2
var dbSclaeCount = 3
var dbAvailabilitySetName_var = 'DbAvlSet'

resource newDBStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newDBStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource appGatewayPubIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: appGatewayPubIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource appServersPublicIPPrefix_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, appScaleCount): {
  name: concat(appServersPublicIPPrefix, i)
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource VNetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: VNetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: FESubnetName
        properties: {
          addressPrefix: FrontendPrefix
          networkSecurityGroup: {
            id: FeNsgname.id
          }
        }
      }
      {
        name: AppSubnetName
        properties: {
          addressPrefix: AppPrefix
          networkSecurityGroup: {
            id: AppNsgname.id
          }
        }
      }
      {
        name: BESubnetName
        properties: {
          addressPrefix: BackendPrefix
          networkSecurityGroup: {
            id: BeNsgname.id
          }
        }
      }
    ]
  }
}

resource FeNsgname 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: FeNsgname_var
  location: location
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
          description: 'Allow Website'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'App_subnet_rule'
        properties: {
          description: 'Outbound to App'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: AppPrefix
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
      {
        name: 'Block_Internal_Network'
        properties: {
          description: 'Outbound to Internal Network'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 2000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource AppNsgname 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: AppNsgname_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'fe_rule'
        properties: {
          description: 'Allow Frontend'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: FrontendPrefix
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
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'vnet_rule'
        properties: {
          description: 'Block Internal Network'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'DB_outbound_rule'
        properties: {
          description: 'Allow Outbound DB'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: BackendPrefix
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
      {
        name: 'Deny_Internet'
        properties: {
          description: 'Deny_Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 2000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource BeNsgname 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: BeNsgname_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'app_rule'
        properties: {
          description: 'Allow App servers'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: AppPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'vnet_rule'
        properties: {
          description: 'Block Internal Network'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny_Internet'
        properties: {
          description: 'Deny_Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource appGatewayName 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: appGatewayName_var
  location: location
  properties: {
    sku: {
      name: skuName
      tier: 'Standard'
      capacity: appGatewayCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', VNetName_var, FESubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPubIPName.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: AppServerIP1
            }
            {
              ipAddress: AppServerIP2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Enabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', appGatewayName_var, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts/', appGatewayName_var, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners/', appGatewayName_var, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', appGatewayName_var, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', appGatewayName_var, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource multitierILB_resource 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: multitierILB
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', VNetName_var, BESubnetName)
          }
          privateIPAddress: ILBIP
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', multitierILB, 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', multitierILB, 'BackendPool1')
          }
          protocol: 'Tcp'
          frontendPort: 1433
          backendPort: 1433
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', multitierILB, 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 1433
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource appNicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, appScaleCount): {
  name: concat(appNicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.1.${(i + 4)}'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(appServersPublicIPPrefix, i))
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', VNetName_var, AppSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses/', concat(appServersPublicIPPrefix, i))
    VNetName
  ]
}]

resource dbNicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, dbSclaeCount): {
  name: concat(dbNicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.2.${(i + 4)}'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', VNetName_var, BESubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', multitierILB, 'BackendPool1')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    VNetName
    multitierILB_resource
  ]
}]

resource appAvailabilitySetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: appAvailabilitySetName_var
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource appVmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, appScaleCount): {
  name: concat(appVmNamePrefix, i)
  location: location
  properties: {
    availabilitySet: {
      id: appAvailabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(appVmNamePrefix, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(appNicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', concat(appNicName_var, i))
    appAvailabilitySetName
  ]
}]

resource dbAvailabilitySetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: dbAvailabilitySetName_var
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource dbVmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, dbSclaeCount): {
  name: concat(dbVmNamePrefix, i)
  location: location
  properties: {
    availabilitySet: {
      id: dbAvailabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(dbVmNamePrefix, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(dbNicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', concat(dbNicName_var, i))
    dbAvailabilitySetName
  ]
}]
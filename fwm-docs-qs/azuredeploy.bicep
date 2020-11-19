param adminUsername string {
  metadata: {
    description: 'Admin username for the servers'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the admin account on the servers'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine.'
  }
  default: 'Standard_D2_v3'
}

resource VWan_01 'Microsoft.Network/virtualWans@2019-08-01' = {
  name: 'VWan-01'
  location: location
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: false
    office365LocalBreakoutCategory: 'None'
    type: 'Standard'
  }
}

resource Hub_01 'Microsoft.Network/virtualHubs@2020-04-01' = {
  name: 'Hub-01'
  location: location
  properties: {
    virtualNetworkConnections: [
      {
        name: 'hub-spoke'
        properties: {
          remoteVirtualNetwork: {
            id: Spoke_01.id
          }
          allowHubToRemoteVnetTransit: true
          allowRemoteVnetToUseHubVnetGateways: false
          enableInternetSecurity: true
        }
      }
    ]
    addressPrefix: '10.1.0.0/16'
    virtualWan: {
      id: VWan_01.id
    }
    azureFirewall: {
      id: AzfwTest.id
    }
  }
  dependsOn: [
    VWan_01
  ]
}

resource Policy_01 'Microsoft.Network/firewallPolicies@2020-04-01' = {
  name: 'Policy-01'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource Policy_01_DefaultApplicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleGroups@2020-04-01' = {
  name: 'Policy-01/DefaultApplicationRuleCollectionGroup'
  location: location
  properties: {
    priority: 300
    rules: [
      {
        name: 'RC-01'
        priority: 100
        ruleType: 'FirewallPolicyFilterRule'
        action: {
          type: 'Allow'
        }
        ruleConditions: [
          {
            name: 'Allow-msft'
            protocols: [
              {
                protocolType: 'http'
                port: 80
              }
              {
                protocolType: 'https'
                port: 443
              }
            ]
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
            ruleConditionType: 'ApplicationRuleCondition'
          }
        ]
      }
    ]
  }
  dependsOn: [
    Policy_01
  ]
}

resource AzfwTest 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: 'AzfwTest'
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: Hub_01.id
    }
    firewallPolicy: {
      id: Policy_01.id
    }
  }
  dependsOn: [
    Hub_01
    Policy_01
  ]
}

resource Spoke_01 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'Spoke-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource Spoke_01_Workload_SN 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: 'Spoke-01/Workload-SN'
  properties: {
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    Spoke_01
  ]
}

resource Spoke_01_Jump_SN 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: 'Spoke-01/Jump-SN'
  properties: {
    addressPrefix: '10.0.2.0/24'
    routeTable: {
      id: RT_01.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    Spoke_01
    RT_01
  ]
}

resource Jump_Srv 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'Jump-Srv'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: 'Jump-Srv'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: netInterface_jump_srv.id
        }
      ]
    }
  }
  dependsOn: [
    netInterface_jump_srv
  ]
}

resource Workload_Srv 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'Workload-Srv'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: 'Workload-Srv'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: netInterface_workload_srv.id
        }
      ]
    }
  }
  dependsOn: [
    netInterface_workload_srv
  ]
}

resource netInterface_workload_srv 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'netInterface-workload-srv'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke-01', 'Workload-SN')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg_workload_srv.id
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke-01', 'Workload-SN')
    nsg_workload_srv
  ]
}

resource netInterface_jump_srv 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'netInterface-jump-srv'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP_jump_srv.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke-01', 'Jump-SN')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg_jump_srv.id
    }
  }
  dependsOn: [
    publicIP_jump_srv
    resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke-01', 'Jump-SN')
    nsg_jump_srv
  ]
}

resource nsg_jump_srv 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-jump-srv'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsg_workload_srv 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-workload-srv'
  location: location
  properties: {}
}

resource publicIP_jump_srv 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: 'publicIP-jump-srv'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource RT_01 'Microsoft.Network/routeTables@2020-06-01' = {
  name: 'RT-01'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'jump-to-inet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

resource Hub_01_VirtualNetworkRouteTable 'Microsoft.Network/virtualHubs/routeTables@2020-04-01' = {
  name: 'Hub-01/VirtualNetworkRouteTable'
  location: location
  properties: {
    routes: [
      {
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
          '0.0.0.0/0'
        ]
        nextHopType: 'IPAddress'
        nextHops: [
          '10.1.64.4'
        ]
      }
    ]
    attachedConnections: [
      'All_Vnets'
    ]
  }
  dependsOn: [
    Hub_01
    AzfwTest
  ]
}

resource Hub_01_BranchRouteTable 'Microsoft.Network/virtualHubs/routeTables@2020-04-01' = {
  name: 'Hub-01/BranchRouteTable'
  location: location
  properties: {
    routes: [
      {
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'IPAddress'
        nextHops: [
          '10.1.64.4'
        ]
      }
    ]
    attachedConnections: [
      'All_Branches'
    ]
  }
  dependsOn: [
    Hub_01
    AzfwTest
    resourceId('Microsoft.Network/virtualHubs/routeTables', 'Hub-01', 'VirtualNetworkRouteTable')
  ]
}
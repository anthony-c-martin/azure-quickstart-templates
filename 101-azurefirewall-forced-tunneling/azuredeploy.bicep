@description('virtual network name to tunnel from')
param virtualNetworkName string = 'from-vnet'

@description('virtual network name to tunnel to')
param tunnelToVirtualNetworkName string = 'to-vnet'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Location for all resources, the location must support Availability Zones if required.')
param location string = resourceGroup().location

@description('Zone numbers e.g. 1,2,3.')
param availabilityZones array = []

@description('Zone numbers e.g. 1,2,3.')
param vmSize string = 'Standard_DS1_v2'

@minValue(1)
@maxValue(100)
@description('Number of public IP addresses for the Azure Firewall')
param numberOfFirewallPublicIPAddresses int = 1

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vnetAddressPrefix = '10.0.0.0/16'
var serversSubnetPrefix = '10.0.2.0/24'
var azureFirewallSubnetPrefix = '10.0.1.0/24'
var azureFirewallMgmtSubnetPrefix = '10.0.3.0/24'
var jumpboxSubnetPrefix = '10.0.0.0/24'
var nextHopIP = '10.0.1.4'
var tunnelToVnetAddressPrefix = '172.16.0.0/16'
var tunnelToAzureFirewallSubnetPrefix = '172.16.1.0/24'
var tunnelToNextHopIP = '172.16.1.4'
var tunnelToPublicIpName_var = 'tunnelToPIP'
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var azureFirewallMgmtSubnetName = 'AzureFirewallManagementSubnet'
var jumpBoxSubnetName = 'JumpboxSubnet'
var serversSubnetName = 'ServersSubnet'
var jumpBoxPublicIPAddressName_var = 'JumpHostPublicIP'
var jumpBoxNsgName_var = 'JumpHostNSG'
var jumpBoxNicName_var = 'JumpHostNic'
var jumpBoxSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, jumpBoxSubnetName)
var serverNicName_var = 'ServerNic'
var serverSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, serversSubnetName)
var storageAccountName_var = '${uniqueString(resourceGroup().id)}sajumpbox'
var azfwRouteTableName_var = 'AzfwRouteTable'
var firewallName_var = 'firewall1'
var tunnelToFirewallName_var = 'tunnelToFirewall'
var publicIPNamePrefix = 'AzFwDataPublicIP'
var managementPublicIpName_var = 'AzFwManagementPublicIP'
var managementPublicIpId = managementPublicIpName.id
var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, azureFirewallSubnetName)
var tunnelToAzureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', tunnelToVirtualNetworkName, azureFirewallSubnetName)
var azureFirewallMgmtSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, azureFirewallMgmtSubnetName)
var azureFirewallSubnetJSON = json('{{"id": "${azureFirewallSubnetId}"}}')
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
var azureFirewallIpConfigurations = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: 'IpConf${i}'
  properties: {
    subnet: ((i == 0) ? azureFirewallSubnetJSON : json('null'))
    publicIPAddress: {
      id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPNamePrefix, (i + 1)))
    }
  }
}]

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource azfwRouteTableName 'Microsoft.Network/routeTables@2019-04-01' = {
  name: azfwRouteTableName_var
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'AzfwDefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nextHopIP
        }
      }
    ]
  }
}

resource TunnelToRouteTable 'Microsoft.Network/routeTables@2019-04-01' = {
  name: 'TunnelToRouteTable'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'TunnelToDefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: tunnelToNextHopIP
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: virtualNetworkName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: jumpBoxSubnetName
        properties: {
          addressPrefix: jumpboxSubnetPrefix
        }
      }
      {
        name: azureFirewallMgmtSubnetName
        properties: {
          addressPrefix: azureFirewallMgmtSubnetPrefix
        }
      }
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: azureFirewallSubnetPrefix
          routeTable: {
            id: TunnelToRouteTable.id
          }
        }
      }
      {
        name: serversSubnetName
        properties: {
          addressPrefix: serversSubnetPrefix
          routeTable: {
            id: azfwRouteTableName.id
          }
        }
      }
    ]
  }
}

resource tunnelToVirtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: tunnelToVirtualNetworkName
  location: location
  tags: {
    displayName: tunnelToVirtualNetworkName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        tunnelToVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: tunnelToAzureFirewallSubnetPrefix
        }
      }
    ]
  }
}

resource virtualNetworkName_TunnelToPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-04-01' = {
  parent: virtualNetworkName_resource
  name: 'TunnelToPeering'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: tunnelToVirtualNetworkName_resource.id
    }
  }
}

resource tunnelToVirtualNetworkName_TunnelFromPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-04-01' = {
  parent: tunnelToVirtualNetworkName_resource
  name: 'TunnelFromPeering'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworkName_resource.id
    }
  }
}

resource publicIPNamePrefix_1 'Microsoft.Network/publicIPAddresses@2019-04-01' = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: concat(publicIPNamePrefix, (i + 1))
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource managementPublicIpName 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: managementPublicIpName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource tunnelToPublicIpName 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: tunnelToPublicIpName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource jumpBoxPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: jumpBoxPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource jumpBoxNsgName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: jumpBoxNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'myNetworkSecurityGroupRuleSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource JumpBoxNicName 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: jumpBoxNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jumpBoxPublicIPAddressName.id
          }
          subnet: {
            id: jumpBoxSubnetId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: jumpBoxNsgName.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource ServerNicName 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: serverNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: serverSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource JumpBox 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: 'JumpBox'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'JumpBox'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: JumpBoxNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource Server 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: 'Server'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'Server'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ServerNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource firewallName 'Microsoft.Network/azureFirewalls@2019-11-01' = {
  name: firewallName_var
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : availabilityZones)
  properties: {
    ipConfigurations: azureFirewallIpConfigurations
    managementIpConfiguration: {
      name: 'ManagementIpConf'
      properties: {
        subnet: {
          id: azureFirewallMgmtSubnetId
        }
        publicIPAddress: {
          id: managementPublicIpId
        }
      }
    }
    applicationRuleCollections: [
      {
        name: 'appRc1'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'appRule1'
              protocols: [
                {
                  port: '80'
                  protocolType: 'Http'
                }
                {
                  port: '443'
                  protocolType: 'Https'
                }
              ]
              targetFqdns: [
                '*'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRc1'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'netRule1'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.2.0/24'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPNamePrefix_1
  ]
}

resource tunnelToFirewallName 'Microsoft.Network/azureFirewalls@2019-11-01' = {
  name: tunnelToFirewallName_var
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : availabilityZones)
  properties: {
    ipConfigurations: [
      {
        name: 'tunnelToPIP'
        properties: {
          publicIPAddress: {
            id: tunnelToPublicIpName.id
          }
          subnet: {
            id: tunnelToAzureFirewallSubnetId
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'appRc1'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'appRule1'
              protocols: [
                {
                  port: '80'
                  protocolType: 'Http'
                }
                {
                  port: '443'
                  protocolType: 'Https'
                }
              ]
              targetFqdns: [
                '*microsoft.com'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRc1'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'netRule1'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.1.0/24'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '8000-8999'
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    tunnelToVirtualNetworkName_resource
  ]
}
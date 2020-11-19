param location1 string {
  metadata: {
    description: 'Location where first VNET, Gateway, PublicIP and Connection will be deployed.'
  }
}
param location2 string {
  metadata: {
    description: 'Location where second VNET, Gateway, PublicIP and Connection will be deployed.'
  }
}
param virtualNetworkName1 string {
  metadata: {
    description: 'Name of the first VNET.'
  }
}
param addressPrefix1 string {
  metadata: {
    description: 'Address space for the first VNET.'
  }
}
param subnet1Name1 string {
  metadata: {
    description: 'Name of the first subnet in the first VNET. Please note, an additional subnet called GatewaySubnet will be created where the VirtualNetworkGateway will be deployed. The name of that subnet must not be changed from GatewaySubnet.'
  }
  default: 'Subnet-1'
}
param subnet1Prefix1 string {
  metadata: {
    description: 'The prefix for the first subnet in the first VNET.'
  }
}
param gatewaySubnetPrefix1 string {
  metadata: {
    description: 'The prefix for the GatewaySubnet where the first VirtualNetworkGateway will be deployed. This must be at least /29.'
  }
}
param gatewayPublicIPName1 string {
  metadata: {
    description: 'The name of the PublicIP attached to the first VirtualNetworkGateway.'
  }
}
param gatewayName1 string {
  metadata: {
    description: 'The name of the first VirtualNetworkGateway.'
  }
}
param connectionName1 string {
  metadata: {
    description: 'The name of the first connection, connecting the first VirtualNetworkGateway to the second VirtualNetworkGateway.'
  }
}
param virtualNetworkName2 string {
  metadata: {
    description: 'Name of the second VNET.'
  }
}
param addressPrefix2 string {
  metadata: {
    description: 'Address space for the second VNET.'
  }
}
param subnet1Name2 string {
  metadata: {
    description: 'Name of the first subnet in the second VNET. Please note, an additional subnet called GatewaySubnet will be created where the VirtualNetworkGateway will be deployed. The name of that subnet must not be changed from GatewaySubnet.'
  }
  default: 'Subnet-1'
}
param subnet1Prefix2 string {
  metadata: {
    description: 'The prefix for the first subnet in the second VNET.'
  }
}
param gatewaySubnetPrefix2 string {
  metadata: {
    description: 'The prefix for the GatewaySubnet where the second VirtualNetworkGateway will be deployed. This must be at least /29.'
  }
}
param gatewayPublicIPName2 string {
  metadata: {
    description: 'The name of the PublicIP attached to the second VirtualNetworkGateway.'
  }
}
param gatewayName2 string {
  metadata: {
    description: 'The name of the second VirtualNetworkGateway.'
  }
}
param connectionName2 string {
  metadata: {
    description: 'The name of the second connection, connecting the second VirtualNetworkGateway to the first VirtualNetworkGateway.'
  }
}
param sharedKey string {
  metadata: {
    description: 'The shared key used to establish connection between the two VirtualNetworkGateways.'
  }
}

resource virtualNetworkName1_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName1
  location: location1
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix1
      ]
    }
    subnets: [
      {
        name: subnet1Name1
        properties: {
          addressPrefix: subnet1Prefix1
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix1
        }
      }
    ]
  }
}

resource virtualNetworkName2_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName2
  location: location2
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix2
      ]
    }
    subnets: [
      {
        name: subnet1Name2
        properties: {
          addressPrefix: subnet1Prefix2
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix2
        }
      }
    ]
  }
}

resource gatewayPublicIPName1_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: gatewayPublicIPName1
  location: location1
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayPublicIPName2_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: gatewayPublicIPName2
  location: location2
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName1_resource 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: gatewayName1
  location: location1
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName1, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: gatewayPublicIPName1_resource.id
          }
        }
        name: 'vnetGatewayConfig1'
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
  dependsOn: [
    gatewayPublicIPName1_resource
    virtualNetworkName1_resource
  ]
}

resource gatewayName2_resource 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: gatewayName2
  location: location2
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName2, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: gatewayPublicIPName2_resource.id
          }
        }
        name: 'vnetGatewayConfig2'
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
  dependsOn: [
    gatewayPublicIPName2_resource
    virtualNetworkName2_resource
  ]
}

resource connectionName1_resource 'Microsoft.Network/connections@2020-05-01' = {
  name: connectionName1
  location: location1
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName1_resource.id
    }
    virtualNetworkGateway2: {
      id: gatewayName2_resource.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
  }
  dependsOn: [
    gatewayName1_resource
    gatewayName2_resource
  ]
}

resource connectionName2_resource 'Microsoft.Network/connections@2020-05-01' = {
  name: connectionName2
  location: location2
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName2_resource.id
    }
    virtualNetworkGateway2: {
      id: gatewayName1_resource.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
  }
  dependsOn: [
    gatewayName1_resource
    gatewayName2_resource
  ]
}
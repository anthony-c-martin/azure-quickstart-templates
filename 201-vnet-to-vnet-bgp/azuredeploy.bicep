param sharedKey string {
  metadata: {
    description: 'The shared key used to establish connection between the two vNet Gateways.'
  }
  secure: true
}
param gatewaySku string {
  allowed: [
    'Standard'
    'HighPerformance'
    'VpnGw1'
    'VpnGw2'
    'VpnGw3'
  ]
  metadata: {
    description: 'The SKU for the VPN Gateway. Cannot be Basic SKU.'
  }
  default: 'VpnGw1'
}
param location string {
  metadata: {
    description: 'Location of the resources'
  }
  default: resourceGroup().location
}

var vNet1 = {
  name: 'vNet1-${location}'
  addressSpacePrefix: '10.0.0.0/23'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.0.0/24'
  gatewayName: 'vNet1-Gateway'
  gatewaySubnetPrefix: '10.0.1.224/27'
  gatewayPublicIPName: 'gw1pip${uniqueString(resourceGroup().id)}'
  connectionName: 'vNet1-to-vNet2'
  asn: 65010
}
var vNet2 = {
  name: 'vNet2-${location}'
  addressSpacePrefix: '10.0.2.0/23'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.2.0/24'
  gatewayName: 'vNet2-Gateway'
  gatewaySubnetPrefix: '10.0.3.224/27'
  gatewayPublicIPName: 'gw2pip${uniqueString(resourceGroup().id)}'
  connectionName: 'vNet2-to-vNet1'
  asn: 65050
}

resource vNet1_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet1.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet1.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet1.subnetName
        properties: {
          addressPrefix: vNet1.subnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: vNet1.gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource vNet2_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet2.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet2.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet2.subnetName
        properties: {
          addressPrefix: vNet2.subnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: vNet2.gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource vNet1_gatewayPublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: vNet1.gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet2_gatewayPublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: vNet2.gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet1_gatewayName 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: vNet1.gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: vNet1_gatewayPublicIPName.id
          }
        }
        name: 'vNet1GatewayConfig'
      }
    ]
    gatewayType: 'Vpn'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: vNet1.asn
    }
  }
  dependsOn: [
    vNet1_gatewayPublicIPName
    vNet1_name
  ]
}

resource vNet2_gatewayName 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: vNet2.gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: vNet2_gatewayPublicIPName.id
          }
        }
        name: 'vNet2GatewayConfig'
      }
    ]
    gatewayType: 'Vpn'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: vNet2.asn
    }
  }
  dependsOn: [
    vNet2_gatewayPublicIPName
    vNet2_name
  ]
}

resource vNet1_connectionName 'Microsoft.Network/connections@2020-05-01' = {
  name: vNet1.connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: vNet1_gatewayName.id
    }
    virtualNetworkGateway2: {
      id: vNet2_gatewayName.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
    enableBGP: true
  }
  dependsOn: [
    vNet1_gatewayName
    vNet2_gatewayName
  ]
}

resource vNet2_connectionName 'Microsoft.Network/connections@2020-05-01' = {
  name: vNet2.connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: vNet2_gatewayName.id
    }
    virtualNetworkGateway2: {
      id: vNet1_gatewayName.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
    enableBGP: true
  }
  dependsOn: [
    vNet1_gatewayName
    vNet2_gatewayName
  ]
}
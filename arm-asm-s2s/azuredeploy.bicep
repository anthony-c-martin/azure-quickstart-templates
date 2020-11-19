param enableBgp string {
  allowed: [
    'false'
  ]
  metadata: {
    description: 'Enable or disable BGP'
  }
  default: 'false'
}
param gatewayType string {
  allowed: [
    'Vpn'
    'ER'
  ]
  metadata: {
    description: 'VPN or ER'
  }
  default: 'Vpn'
}
param vpnType string {
  allowed: [
    'RouteBased'
    'PolicyBased'
  ]
  metadata: {
    description: 'Route based or policy based'
  }
  default: 'RouteBased'
}
param localGatewayName string {
  metadata: {
    description: 'Name for gateway connected to other VNet/on-prem network'
  }
}
param localGatewayIpAddress string {
  metadata: {
    description: 'Public IP address for the gateway to connect to (from other VNet/on-prem)'
  }
}
param localGatewayAddressPrefix string {
  metadata: {
    description: 'CIDR block for remote network'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'Name for new virtual network'
  }
}
param addressPrefix string {
  metadata: {
    description: 'Name for new virtual network'
  }
}
param subnet1Name string {
  metadata: {
    description: 'Name for VM subnet in the new VNet'
  }
  default: 'Subnet1'
}
param gatewaySubnet string {
  allowed: [
    'GatewaySubnet'
  ]
  metadata: {
    description: 'Name for gateway subnet in new VNet'
  }
  default: 'GatewaySubnet'
}
param subnet1Prefix string {
  metadata: {
    description: 'CIDR block for VM subnet'
  }
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'CIDR block for gateway subnet'
  }
}
param gatewayPublicIPName string {
  metadata: {
    description: 'Name for public IP object used for the new gateway'
  }
}
param gatewayName string {
  metadata: {
    description: 'Name for the new gateway'
  }
}

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, gatewaySubnet)

resource localGatewayName_res 'Microsoft.Network/localNetworkGateways@2015-05-01-preview' = {
  name: localGatewayName
  location: resourceGroup().location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        localGatewayAddressPrefix
      ]
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: gatewaySubnet
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource gatewayPublicIPName_res 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: gatewayPublicIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_res 'Microsoft.Network/virtualNetworkGateways@2015-05-01-preview' = {
  name: gatewayName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: gatewayPublicIPName_res.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}
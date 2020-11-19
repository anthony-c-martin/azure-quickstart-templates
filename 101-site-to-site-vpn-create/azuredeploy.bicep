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
    description: 'Arbitrary name for gateway resource representing '
  }
  default: 'localGateway'
}
param localGatewayIpAddress string {
  metadata: {
    description: 'Public IP of your StrongSwan Instance'
  }
  default: '1.1.1.1'
}
param localAddressPrefix array {
  metadata: {
    description: 'CIDR block representing the address space of the OnPremise VPN network\'s Subnet'
  }
  default: [
    '192.168.0.0/16'
    '172.16.0.0/12'
  ]
}
param virtualNetworkName string {
  metadata: {
    description: 'Arbitrary name for the Azure Virtual Network'
  }
  default: 'azureVnet'
}
param azureVNetAddressPrefix string {
  metadata: {
    description: 'CIDR block representing the address space of the Azure VNet'
  }
  default: '10.3.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Arbitrary name for the Azure Subnet'
  }
  default: 'Subnet1'
}
param subnetPrefix string {
  metadata: {
    description: 'CIDR block for VM subnet, subset of azureVNetAddressPrefix address space'
  }
  default: '10.3.1.0/24'
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'CIDR block for gateway subnet, subset of azureVNetAddressPrefix address space'
  }
  default: '10.3.200.0/29'
}
param gatewayPublicIPName string {
  metadata: {
    description: 'Arbitrary name for public IP resource used for the new azure gateway'
  }
  default: 'azureGatewayIP'
}
param gatewayName string {
  metadata: {
    description: 'Arbitrary name for the new gateway'
  }
  default: 'azureGateway'
}
param gatewaySku string {
  allowed: [
    'Basic'
    'Standard'
    'HighPerformance'
  ]
  metadata: {
    description: 'The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.'
  }
  default: 'Basic'
}
param connectionName string {
  metadata: {
    description: 'Arbitrary name for the new connection between Azure VNet and other network'
  }
  default: 'Azure2Other'
}
param sharedKey string {
  metadata: {
    description: 'Shared key (PSK) for IPSec tunnel'
  }
  secure: true
}

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, 'GatewaySubnet')

resource localGatewayName_resource 'Microsoft.Network/localNetworkGateways@2015-06-15' = {
  name: localGatewayName
  location: resourceGroup().location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: localAddressPrefix
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource connectionName_resource 'Microsoft.Network/connections@2015-06-15' = {
  name: connectionName
  location: resourceGroup().location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName_resource.id
    }
    localNetworkGateway2: {
      id: localGatewayName_resource.id
    }
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: sharedKey
  }
  dependsOn: [
    gatewayName_resource
    localGatewayName_resource
  ]
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        azureVNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
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
            id: gatewayPublicIPName_resource.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: 'Vpn'
    vpnType: vpnType
    enableBgp: 'false'
  }
  dependsOn: [
    gatewayPublicIPName_resource
    virtualNetworkName_resource
  ]
}
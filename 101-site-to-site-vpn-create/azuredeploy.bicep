@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Route based or policy based')
param vpnType string = 'RouteBased'

@description('Arbitrary name for gateway resource representing ')
param localGatewayName string = 'localGateway'

@description('Public IP of your StrongSwan Instance')
param localGatewayIpAddress string = '1.1.1.1'

@description('CIDR block representing the address space of the OnPremise VPN network\'s Subnet')
param localAddressPrefix array = [
  '192.168.0.0/16'
  '172.16.0.0/12'
]

@description('Arbitrary name for the Azure Virtual Network')
param virtualNetworkName string = 'azureVnet'

@description('CIDR block representing the address space of the Azure VNet')
param azureVNetAddressPrefix string = '10.3.0.0/16'

@description('Arbitrary name for the Azure Subnet')
param subnetName string = 'Subnet1'

@description('CIDR block for VM subnet, subset of azureVNetAddressPrefix address space')
param subnetPrefix string = '10.3.1.0/24'

@description('CIDR block for gateway subnet, subset of azureVNetAddressPrefix address space')
param gatewaySubnetPrefix string = '10.3.200.0/29'

@description('Arbitrary name for public IP resource used for the new azure gateway')
param gatewayPublicIPName string = 'azureGatewayIP'

@description('Arbitrary name for the new gateway')
param gatewayName string = 'azureGateway'

@allowed([
  'Basic'
  'Standard'
  'HighPerformance'
])
@description('The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.')
param gatewaySku string = 'Basic'

@description('Arbitrary name for the new connection between Azure VNet and other network')
param connectionName string = 'Azure2Other'

@description('Shared key (PSK) for IPSec tunnel')
@secure()
param sharedKey string

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
    virtualNetworkName_resource
  ]
}
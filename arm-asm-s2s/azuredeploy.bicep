@allowed([
  'false'
])
@description('Enable or disable BGP')
param enableBgp string = 'false'

@allowed([
  'Vpn'
  'ER'
])
@description('VPN or ER')
param gatewayType string = 'Vpn'

@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Route based or policy based')
param vpnType string = 'RouteBased'

@description('Name for gateway connected to other VNet/on-prem network')
param localGatewayName string

@description('Public IP address for the gateway to connect to (from other VNet/on-prem)')
param localGatewayIpAddress string

@description('CIDR block for remote network')
param localGatewayAddressPrefix string

@description('Name for new virtual network')
param virtualNetworkName string

@description('Name for new virtual network')
param addressPrefix string

@description('Name for VM subnet in the new VNet')
param subnet1Name string = 'Subnet1'

@allowed([
  'GatewaySubnet'
])
@description('Name for gateway subnet in new VNet')
param gatewaySubnet string = 'GatewaySubnet'

@description('CIDR block for VM subnet')
param subnet1Prefix string

@description('CIDR block for gateway subnet')
param gatewaySubnetPrefix string

@description('Name for public IP object used for the new gateway')
param gatewayPublicIPName string

@description('Name for the new gateway')
param gatewayName string

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, gatewaySubnet)

resource localGatewayName_resource 'Microsoft.Network/localNetworkGateways@2015-05-01-preview' = {
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: gatewayPublicIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2015-05-01-preview' = {
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
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}
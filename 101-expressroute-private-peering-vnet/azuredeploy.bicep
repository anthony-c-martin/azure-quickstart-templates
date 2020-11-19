param location string {
  metadata: {
    description: 'Location for all resources deployed in the ARM template'
  }
  default: resourceGroup().location
}
param erpeeringLocation string {
  metadata: {
    description: 'ExpressRoute peering location'
  }
  default: 'Washington DC'
}
param erCircuitName string {
  metadata: {
    description: 'Name of the ExpressRoute circuit'
  }
  default: 'er-ckt01'
}
param serviceProviderName string {
  metadata: {
    description: 'Name of the ExpressRoute provider'
  }
  default: 'Equinix'
}
param erSKU_Tier string {
  allowed: [
    'Premium'
    'Standard'
  ]
  metadata: {
    description: 'Tier ExpressRoute circuit'
  }
  default: 'Premium'
}
param erSKU_Family string {
  allowed: [
    'MeteredData'
    'UnlimitedData'
  ]
  metadata: {
    description: 'Billing model ExpressRoute circuit'
  }
  default: 'MeteredData'
}
param bandwidthInMbps int {
  allowed: [
    50
    100
    200
    500
    1000
    2000
    5000
    10000
  ]
  metadata: {
    description: 'Bandwidth ExpressRoute circuit'
  }
  default: 50
}
param peerASN int {
  metadata: {
    description: 'autonomous system number used to create private peering between the customer edge router and MSEE routers'
  }
  default: 65001
}
param primaryPeerAddressPrefix string {
  metadata: {
    description: 'point-to-point network prefix of primary link between the customer edge router and MSEE router'
  }
  default: '192.168.10.16/30'
}
param secondaryPeerAddressPrefix string {
  metadata: {
    description: 'point-to-point network prefix of secondary link between the customer edge router and MSEE router'
  }
  default: '192.168.10.20/30'
}
param vlanId int {
  metadata: {
    description: 'VLAN Id used between the customer edge routers and MSEE routers. primary and secondary link have the same VLAN Id'
  }
  default: 100
}
param vnetName string {
  metadata: {
    description: 'name of the Virtual Network'
  }
  default: 'vnet1'
}
param subnet1Name string {
  metadata: {
    description: 'name of the subnet'
  }
  default: 'subnet1'
}
param vnetAddressSpace string {
  metadata: {
    description: 'address space assigned to the Virtual Network'
  }
  default: '10.10.10.0/24'
}
param subnet1Prefix string {
  metadata: {
    description: 'network prefix assigned to the subnet'
  }
  default: '10.10.10.0/25'
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'network prefixes assigned to the gateway subnet. It has to be a network prefix with mask /27 or larger'
  }
  default: '10.10.10.224/27'
}
param gatewayName string {
  metadata: {
    description: 'name of the ExpressRoute Gateway'
  }
  default: 'er-gw'
}
param gatewaySku string {
  allowed: [
    'Standard'
    'HighPerformance'
    'UltraPerformance'
    'ErGw1AZ'
    'ErGw2AZ'
    'ErGw3AZ'
  ]
  metadata: {
    description: 'ExpressRoute Gateway SKU'
  }
  default: 'HighPerformance'
}

var location_variable = location
var erlocation = location
var erCircuitName_variable = erCircuitName
var serviceProviderName_variable = serviceProviderName
var erpeeringLocation_variable = erpeeringLocation
var erSKU_Tier_variable = erSKU_Tier
var erSKU_Family_variable = erSKU_Family
var erSKU_Name = '${erSKU_Tier_variable}_${erSKU_Family_variable}'
var bandwidthInMbps_variable = bandwidthInMbps
var peerASN_variable = peerASN
var primaryPeerAddressPrefix_variable = primaryPeerAddressPrefix
var secondaryPeerAddressPrefix_variable = secondaryPeerAddressPrefix
var vlanId_variable = vlanId
var vnetName_variable = vnetName
var subnet1Name_variable = subnet1Name
var vnetAddressSpace_variable = vnetAddressSpace
var subnet1Prefix_variable = subnet1Prefix
var gatewaySubnetPrefix_variable = gatewaySubnetPrefix
var gatewayName_variable = gatewayName
var gatewayPublicIPName = '${gatewayName_variable}-pubIP'
var gatewaySku_variable = gatewaySku
var nsg = 'nsg'

resource erCircuitName_resource 'Microsoft.Network/expressRouteCircuits@2020-06-01' = {
  name: erCircuitName_variable
  location: erlocation
  sku: {
    name: erSKU_Name
    tier: erSKU_Tier_variable
    family: erSKU_Family_variable
  }
  properties: {
    serviceProviderProperties: {
      serviceProviderName: serviceProviderName_variable
      peeringLocation: erpeeringLocation_variable
      bandwidthInMbps: bandwidthInMbps_variable
    }
    allowClassicOperations: false
  }
}

resource erCircuitName_AzurePrivatePeering 'Microsoft.Network/expressRouteCircuits/peerings@2020-06-01' = {
  name: '${erCircuitName_variable}/AzurePrivatePeering'
  location: erlocation
  properties: {
    peeringType: 'AzurePrivatePeering'
    peerASN: peerASN_variable
    primaryPeerAddressPrefix: primaryPeerAddressPrefix_variable
    secondaryPeerAddressPrefix: secondaryPeerAddressPrefix_variable
    vlanId: vlanId_variable
  }
  dependsOn: [
    erCircuitName_resource
  ]
}

resource nsg_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsg
  location: location_variable
  properties: {
    securityRules: [
      {
        name: 'SSH-rule'
        properties: {
          description: 'allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 500
          direction: 'Inbound'
        }
      }
      {
        name: 'RDP-rule'
        properties: {
          description: 'allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 600
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName_variable
  location: location_variable
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace_variable
      ]
    }
    subnets: [
      {
        name: subnet1Name_variable
        properties: {
          addressPrefix: subnet1Prefix_variable
          networkSecurityGroup: {
            id: nsg_resource.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix_variable
        }
      }
    ]
  }
  dependsOn: [
    nsg_resource
  ]
}

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: gatewayPublicIPName
  location: location_variable
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2020-06-01' = {
  name: gatewayName_variable
  location: location_variable
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_variable, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: gatewayPublicIPName_resource.id
          }
        }
        name: 'gwIPconf'
      }
    ]
    gatewayType: 'ExpressRoute'
    sku: {
      name: gatewaySku_variable
      tier: gatewaySku_variable
    }
    vpnType: 'RouteBased'
  }
  dependsOn: [
    gatewayPublicIPName_resource
    vnetName_resource
  ]
}

output erCircuitName_output string = erCircuitName_variable
output gatewayName_output string = gatewayName_variable
output gatewaySku_output string = gatewaySku_variable
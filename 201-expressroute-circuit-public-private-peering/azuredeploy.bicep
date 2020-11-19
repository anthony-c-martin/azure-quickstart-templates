param circuitName string {
  metadata: {
    description: 'This is the name of the ExpressRoute circuit'
  }
}
param serviceProviderName string {
  metadata: {
    description: 'This is the name of the ExpressRoute Service Provider. It must exactly match one of the Service Providers from List ExpressRoute Service Providers API call.'
  }
}
param peeringLocation string {
  metadata: {
    description: 'This is the name of the peering location and not the ARM resource location. It must exactly match one of the available peering locations from List ExpressRoute Service Providers API call.'
  }
}
param bandwidthInMbps int {
  metadata: {
    description: 'This is the bandwidth in Mbps of the circuit being created. It must exactly match one of the available bandwidth offers List ExpressRoute Service Providers API call.'
  }
}
param sku_tier string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Chosen SKU Tier of ExpressRoute circuit. Choose from Premium or Standard SKU tiers.'
  }
  default: 'Standard'
}
param sku_family string {
  allowed: [
    'MeteredData'
    'UnlimitedData'
  ]
  metadata: {
    description: 'Chosen SKU family of ExpressRoute circuit. Choose from MeteredData or UnlimitedData SKU families.'
  }
  default: 'MeteredData'
}
param peeringType string {
  allowed: [
    'AzurePrivatePeering'
    'AzurePublicPeering'
    'MicrosoftPeering'
  ]
  metadata: {
    description: 'BGP peering type for the Circuit. Choose from AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering.'
  }
  default: 'AzurePrivatePeering'
}
param sharedKey string {
  metadata: {
    description: 'The shared key for peering configuration. Router does MD5 hash comparison to validate the packets sent by BGP connection. This parameter is optional and can be removed from peering configuration if not required.'
  }
}
param peerASN int {
  metadata: {
    description: 'The autonomous system number of the customer/connectivity provider.'
  }
}
param primaryPeerAddressPrefix string {
  metadata: {
    description: '/30 subnet used to configure IP addresses for interfaces on Link1.'
  }
}
param secondaryPeerAddressPrefix string {
  metadata: {
    description: '/30 subnet used to configure IP addresses for interfaces on Link2.'
  }
}
param vlanId int {
  metadata: {
    description: 'Specifies the identifier that is used to identify the customer.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource circuitName_res 'Microsoft.Network/expressRouteCircuits@2015-05-01-preview' = {
  name: circuitName
  location: location
  tags: {
    key1: 'value1'
    key2: 'value2'
  }
  sku: {
    name: '${sku_tier}_${sku_family}'
    tier: sku_tier
    family: sku_family
  }
  properties: {
    serviceProviderProperties: {
      serviceProviderName: serviceProviderName
      peeringLocation: peeringLocation
      bandwidthInMbps: bandwidthInMbps
    }
    peerings: [
      {
        name: peeringType
        properties: {
          peeringType: peeringType
          sharedKey: sharedKey
          peerASN: peerASN
          primaryPeerAddressPrefix: primaryPeerAddressPrefix
          secondaryPeerAddressPrefix: secondaryPeerAddressPrefix
          vlanId: vlanId
        }
      }
    ]
  }
}
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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource circuitName_resource 'Microsoft.Network/expressRouteCircuits@2019-04-01' = {
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
  }
}
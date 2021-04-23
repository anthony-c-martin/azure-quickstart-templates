@description('This is the name of the ExpressRoute circuit')
param circuitName string

@description('This is the name of the ExpressRoute Service Provider. It must exactly match one of the Service Providers from List ExpressRoute Service Providers API call.')
param serviceProviderName string

@description('This is the name of the peering location and not the ARM resource location. It must exactly match one of the available peering locations from List ExpressRoute Service Providers API call.')
param peeringLocation string

@description('This is the bandwidth in Mbps of the circuit being created. It must exactly match one of the available bandwidth offers List ExpressRoute Service Providers API call.')
param bandwidthInMbps int

@allowed([
  'Standard'
  'Premium'
])
@description('Chosen SKU Tier of ExpressRoute circuit. Choose from Premium or Standard SKU tiers.')
param sku_tier string = 'Standard'

@allowed([
  'MeteredData'
  'UnlimitedData'
])
@description('Chosen SKU family of ExpressRoute circuit. Choose from MeteredData or UnlimitedData SKU families.')
param sku_family string = 'MeteredData'

@description('Location for all resources.')
param location string = resourceGroup().location

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
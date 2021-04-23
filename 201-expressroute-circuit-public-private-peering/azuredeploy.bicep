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

@allowed([
  'AzurePrivatePeering'
  'AzurePublicPeering'
  'MicrosoftPeering'
])
@description('BGP peering type for the Circuit. Choose from AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering.')
param peeringType string = 'AzurePrivatePeering'

@description('The shared key for peering configuration. Router does MD5 hash comparison to validate the packets sent by BGP connection. This parameter is optional and can be removed from peering configuration if not required.')
param sharedKey string

@description('The autonomous system number of the customer/connectivity provider.')
param peerASN int

@description('/30 subnet used to configure IP addresses for interfaces on Link1.')
param primaryPeerAddressPrefix string

@description('/30 subnet used to configure IP addresses for interfaces on Link2.')
param secondaryPeerAddressPrefix string

@description('Specifies the identifier that is used to identify the customer.')
param vlanId int

@description('Location for all resources.')
param location string = resourceGroup().location

resource circuitName_resource 'Microsoft.Network/expressRouteCircuits@2015-05-01-preview' = {
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
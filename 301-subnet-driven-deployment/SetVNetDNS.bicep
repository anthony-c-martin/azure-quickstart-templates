@metadata({
  Description: 'The name of the Virtual to change the DNS on'
})
param virtualNetworkName string

@metadata({
  Description: 'Subnets already created'
})
param virtualNetworkSubnets array

@metadata({
  Description: 'The address ranges of the new VNET in CIDR format'
})
param virtualNetworkAddressRanges array = [
  '10.0.0.0/16'
]

@metadata({
  Description: 'The DNS address(es) of the DNS Server(s) used by the VNET'
})
param dnsServerAddresses array

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetworkAddressRanges
    }
    subnets: virtualNetworkSubnets
    dhcpOptions: {
      dnsServers: dnsServerAddresses
    }
  }
}
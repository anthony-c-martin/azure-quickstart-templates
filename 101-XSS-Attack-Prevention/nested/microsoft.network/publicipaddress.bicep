param publicIPAddressName string
param publicIPAddressType string = 'Dynamic'
param dnsNameForPublicIP string
param location string
param tags object

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2018-06-01' = {
  name: publicIPAddressName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

output publicIPAddressName string = publicIPAddressName
output publicIPRef string = publicIPAddressName_resource.id
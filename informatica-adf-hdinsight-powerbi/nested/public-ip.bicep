param location string {
  metadata: {
    description: 'Public IP Deployment Location'
  }
  default: 'westus'
}
param networkApiVersion string {
  metadata: {
    description: 'API Version for the Network Resources'
  }
  default: '2015-06-15'
}
param publicIPAddressName string {
  metadata: {
    description: 'Public IP Address Name'
  }
  default: 'publicIPAddress'
}
param tag object {
  metadata: {
    description: 'Tag Values'
  }
  default: {
    key1: 'key'
    value1: 'value'
  }
}
param publicIPdnsPrefix string {
  metadata: {
    description: 'Public IP DNS Prefix'
  }
  default: 'publicdnsprefix'
}
param informaticaTags object
param quickstartTags object

resource publicIPAddressName_res 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicIPdnsPrefix
    }
  }
}
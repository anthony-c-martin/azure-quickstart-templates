@description('Public IP Deployment Location')
param location string = 'westus'

@description('API Version for the Network Resources')
param networkApiVersion string = '2015-06-15'

@description('Public IP Address Name')
param publicIPAddressName string = 'publicIPAddress'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}

@description('Public IP DNS Prefix')
param publicIPdnsPrefix string = 'publicdnsprefix'
param informaticaTags object
param quickstartTags object

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
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
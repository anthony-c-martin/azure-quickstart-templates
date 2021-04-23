@description('Virtual Network and Subnets Deployment Location')
param location string = 'westus'

@allowed([
  '2015-05-01-preview'
  '2015-06-15'
  '2016-03-30'
])
@description('API Version for the Network Resources')
param networkApiVersion string = '2015-06-15'

@description('Virtual Network Name')
param vnetName string = 'virtualNetwork'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet1 Name')
param subnet1Name string = 'subnet1'

@description('Subnet1 Address Prefix')
param subnet1Prefix string = '10.0.1.0/24'
param informaticaTags object
param quickstartTags object

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}
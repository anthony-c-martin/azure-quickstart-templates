param location string {
  metadata: {
    description: 'Virtual Network and Subnets Deployment Location'
  }
  default: 'westus'
}
param networkApiVersion string {
  allowed: [
    '2015-05-01-preview'
    '2015-06-15'
    '2016-03-30'
  ]
  metadata: {
    description: 'API Version for the Network Resources'
  }
  default: '2015-06-15'
}
param vnetName string {
  metadata: {
    description: 'Virtual Network Name'
  }
  default: 'virtualNetwork'
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
param vnetAddressPrefix string {
  metadata: {
    description: 'Virtual Network Address Prefix'
  }
  default: '10.0.0.0/16'
}
param subnet1Name string {
  metadata: {
    description: 'Subnet1 Name'
  }
  default: 'subnet1'
}
param subnet1Prefix string {
  metadata: {
    description: 'Subnet1 Address Prefix'
  }
  default: '10.0.1.0/24'
}
param informaticaTags object
param quickstartTags object

resource vnetName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
param location string {
  allowed: [
    'brazilsouth'
    'eastasia'
    'eastus'
    'japaneast'
    'japanwest'
    'northcentralus'
    'northeurope'
    'southcentralus'
    'westeurope'
    'westus'
    'southeastasia'
    'centralus'
    'eastus2'
  ]
  metadata: {
    description: 'Deployments Location'
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
  default: '2016-03-30'
}
param tag object = {
  key1: 'key'
  value1: 'value'
}
param networkSecurityGroupsName string {
  metadata: {
    description: ' Virtual machine name'
  }
  default: 'wowza-nsg'
}
param informaticaTags object
param quickstartTags object

resource networkSecurityGroupsName_resource 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: networkSecurityGroupsName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 1010
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '80'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1020
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
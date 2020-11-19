param location string {
  metadata: {
    description: 'Network Security Group Deployment Location'
  }
  default: 'westus'
}
param networkApiVersion string {
  metadata: {
    description: 'API Version for the Network Resources'
  }
  default: '2015-06-15'
}
param networkInterfaceName string {
  metadata: {
    description: 'Network Interface Name'
  }
  default: 'networkInterface'
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
param networkSecurityGroupName string {
  metadata: {
    description: 'Network Security Group Name'
  }
  default: 'networkSecurityGroup'
}
param publicIPAddressName string {
  metadata: {
    description: 'Public IP Address Name'
  }
  default: 'publicIPAddress'
}
param subnetRef string {
  metadata: {
    description: 'subnet reference where the Network Interface is being Deployed'
  }
  default: 'subnetRef'
}
param informaticaTags object
param quickstartTags object

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: networkInterfaceName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}
@description('Network Security Group Deployment Location')
param location string = 'westus'

@description('API Version for the Network Resources')
param networkApiVersion string = '2015-06-15'

@description('Network Interface Name')
param networkInterfaceName string = 'networkInterface'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}

@description('Network Security Group Name')
param networkSecurityGroupName string = 'networkSecurityGroup'

@description('Public IP Address Name')
param publicIPAddressName string = 'publicIPAddress'

@description('subnet reference where the Network Interface is being Deployed')
param subnetRef string = 'subnetRef'
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
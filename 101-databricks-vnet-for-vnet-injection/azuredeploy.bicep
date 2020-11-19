param nsgId string {
  metadata: {
    description: 'The complete ARM Resource Id for the existing network security group.'
  }
}
param vnetName string {
  metadata: {
    description: 'The name of the virtual network to create.'
  }
  default: 'databricks-vnet'
}
param privateSubnetName string {
  metadata: {
    description: 'The name of the private subnet to create.'
  }
  default: 'private-subnet'
}
param publicSubnetName string {
  metadata: {
    description: 'The name of the public subnet to create.'
  }
  default: 'public-subnet'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vnetCidr string {
  metadata: {
    description: 'Cidr range for the vnet.'
  }
  default: '10.179.0.0/16'
}
param privateSubnetCidr string {
  metadata: {
    description: 'Cidr range for the private subnet.'
  }
  default: '10.179.0.0/18'
}
param publicSubnetCidr string {
  metadata: {
    description: 'Cidr range for the public subnet..'
  }
  default: '10.179.64.0/18'
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: publicSubnetCidr
          networkSecurityGroup: {
            id: nsgId
          }
          delegations: [
            {
              name: 'databricks-del-public'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: privateSubnetName
        properties: {
          addressPrefix: privateSubnetCidr
          networkSecurityGroup: {
            id: nsgId
          }
          delegations: [
            {
              name: 'databricks-del-private'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
    ]
  }
}
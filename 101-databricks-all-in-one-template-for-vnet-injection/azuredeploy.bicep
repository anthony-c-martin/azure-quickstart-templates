param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param nsgName string {
  metadata: {
    description: 'The name of the network security group to create.'
  }
  default: 'databricks-nsg'
}
param pricingTier string {
  allowed: [
    'trial'
    'standard'
    'premium'
  ]
  metadata: {
    description: 'The pricing tier of workspace.'
  }
  default: 'premium'
}
param privateSubnetCidr string {
  metadata: {
    description: 'Cidr range for the private subnet.'
  }
  default: '10.179.0.0/18'
}
param privateSubnetName string {
  metadata: {
    description: 'The name of the private subnet to create.'
  }
  default: 'private-subnet'
}
param publicSubnetCidr string {
  metadata: {
    description: 'Cidr range for the public subnet..'
  }
  default: '10.179.64.0/18'
}
param publicSubnetName string {
  metadata: {
    description: 'The name of the public subnet to create.'
  }
  default: 'public-subnet'
}
param vnetCidr string {
  metadata: {
    description: 'Cidr range for the vnet.'
  }
  default: '10.179.0.0/16'
}
param vnetName string {
  metadata: {
    description: 'The name of the virtual network to create.'
  }
  default: 'databricks-vnet'
}
param workspaceName string {
  metadata: {
    description: 'The name of the Azure Databricks workspace to create.'
  }
}

var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'
var managedResourceGroupId = subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
var nsgId = nsgName_res.id
var vnetId = vnetName_res.id

resource nsgName_res 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  location: location
  name: nsgName
  properties: {}
}

resource vnetName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource workspaceName_res 'Microsoft.Databricks/workspaces@2018-04-01' = {
  location: location
  name: workspaceName
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
    }
  }
}
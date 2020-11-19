param workspaceName string {
  metadata: {
    description: 'The name of the Azure Databricks workspace to create.'
  }
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
param customVirtualNetworkId string {
  metadata: {
    description: 'The complete ARM resource Id of the custom virtual network.'
  }
}
param customPublicSubnetName string {
  metadata: {
    description: 'The name of the public subnet in the custom VNet.'
  }
  default: 'public-subnet'
}
param customPrivateSubnetName string {
  metadata: {
    description: 'The name of the private subnet in the custom VNet.'
  }
  default: 'private-subnet'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var managedResourceGroupId = subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'

resource workspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      customVirtualNetworkId: {
        value: customVirtualNetworkId
      }
      customPublicSubnetName: {
        value: customPublicSubnetName
      }
      customPrivateSubnetName: {
        value: customPrivateSubnetName
      }
    }
  }
}
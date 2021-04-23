@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = false

@description('The name of the Azure Databricks workspace to create.')
param workspaceName string

@allowed([
  'trial'
  'standard'
  'premium'
])
@description('The pricing tier of workspace.')
param pricingTier string = 'premium'

@description('The complete ARM resource Id of the custom virtual network.')
param customVirtualNetworkId string

@description('The name of the public subnet in the custom VNet.')
param customPublicSubnetName string = 'public-subnet'

@description('The name of the private subnet in the custom VNet.')
param customPrivateSubnetName string = 'private-subnet'

@description('Location for all resources.')
param location string = resourceGroup().location

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
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
  }
}
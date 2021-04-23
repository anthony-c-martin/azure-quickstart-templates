@description('Specifies whether to deploy Azure Databricks workspace with secure cluster connectivity (SCC) enabled or not (No Public IP)')
param disablePublicIp bool = false

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the network security group to create.')
param nsgName string = 'databricks-nsg'

@allowed([
  'trial'
  'standard'
  'premium'
])
@description('The pricing tier of workspace.')
param pricingTier string = 'premium'

@description('Cidr range for the private subnet.')
param privateSubnetCidr string = '10.179.0.0/18'

@description('The name of the private subnet to create.')
param privateSubnetName string = 'private-subnet'

@description('Cidr range for the public subnet..')
param publicSubnetCidr string = '10.179.64.0/18'

@description('The name of the public subnet to create.')
param publicSubnetName string = 'public-subnet'

@description('Cidr range for the vnet.')
param vnetCidr string = '10.179.0.0/16'

@description('The name of the virtual network to create.')
param vnetName string = 'databricks-vnet'

@description('The name of the Azure Databricks workspace to create.')
param workspaceName string

var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'
var managedResourceGroupId = subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
var nsgId = nsgName_resource.id
var vnetId = vnetName_resource.id

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  location: location
  name: nsgName
  properties: {}
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

resource workspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
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
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
  }
  dependsOn: [
    nsgName_resource
  ]
}
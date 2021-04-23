@description('The complete ARM Resource Id for the existing network security group.')
param nsgId string

@description('The name of the virtual network to create.')
param vnetName string = 'databricks-vnet'

@description('The name of the private subnet to create.')
param privateSubnetName string = 'private-subnet'

@description('The name of the public subnet to create.')
param publicSubnetName string = 'public-subnet'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Cidr range for the vnet.')
param vnetCidr string = '10.179.0.0/16'

@description('Cidr range for the private subnet.')
param privateSubnetCidr string = '10.179.0.0/18'

@description('Cidr range for the public subnet..')
param publicSubnetCidr string = '10.179.64.0/18'

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
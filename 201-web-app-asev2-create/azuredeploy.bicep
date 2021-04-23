@description('Name of the App Service Environment')
param aseName string

@description('Location of the App Service Environment')
param location string = resourceGroup().location

@description('Name of the existing VNET')
param existingVirtualNetworkName string

@description('Name of the existing VNET resource group')
param existingVirtualNetworkResourceGroup string

@description('Subnet name that will contain the App Service Environment')
param existingSubnetName string

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2020-06-01' = {
  name: aseName
  kind: 'ASEV2'
  location: location
  properties: {
    virtualNetwork: {
      id: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)
    }
  }
}
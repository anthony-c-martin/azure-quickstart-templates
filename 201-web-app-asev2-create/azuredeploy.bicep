param aseName string {
  metadata: {
    description: 'Name of the App Service Environment'
  }
}
param location string {
  metadata: {
    description: 'Location of the App Service Environment'
  }
  default: resourceGroup().location
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Name of the existing VNET'
  }
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'Name of the existing VNET resource group'
  }
}
param existingSubnetName string {
  metadata: {
    description: 'Subnet name that will contain the App Service Environment'
  }
}

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
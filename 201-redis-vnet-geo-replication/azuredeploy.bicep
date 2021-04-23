@description('The location of the existing primary virtual network and new primary cache.')
param location string = resourceGroup().location

@description('The name of the resource group of the existing primary virtual network.')
param existingPrimaryVirtualNetworkResourceGroupName string

@description('The name of the existing primary virtual network.')
param existingPrimaryVirtualNetworkName string

@description('The name of the existing primary cache subnet.')
param existingPrimaryCacheSubnetName string

@description('The name of the new primary cache.')
param newPrimaryCacheName string

@description('The location of the existing secondary virtual network and new secondary cache.')
param secondaryLocation string

@description('The name of the resource group of the existing secondary virtual network.')
param existingSecondaryVirtualNetworkResourceGroupName string

@description('The name of the existing secondary virtual network.')
param existingSecondaryVirtualNetworkName string

@description('The name of the existing secondary cache subnet.')
param existingSecondaryCacheSubnetName string

@description('The name of the new secondary cache.')
param newSecondaryCacheName string

var primarySubnetId = resourceId(existingPrimaryVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingPrimaryVirtualNetworkName, existingPrimaryCacheSubnetName)
var secondarySubnetId = resourceId(existingSecondaryVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingSecondaryVirtualNetworkName, existingSecondaryCacheSubnetName)

resource newPrimaryCacheName_resource 'Microsoft.Cache/Redis@2018-03-01' = {
  name: newPrimaryCacheName
  location: location
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 1
    }
    subnetId: primarySubnetId
  }
}

resource newSecondaryCacheName_resource 'Microsoft.Cache/Redis@2018-03-01' = {
  name: newSecondaryCacheName
  location: secondaryLocation
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 1
    }
    subnetId: secondarySubnetId
  }
}

resource newPrimaryCacheName_newSecondaryCacheName 'Microsoft.Cache/Redis/linkedServers@2018-03-01' = {
  parent: newPrimaryCacheName_resource
  name: '${newSecondaryCacheName}'
  properties: {
    linkedRedisCacheId: newSecondaryCacheName_resource.id
    linkedRedisCacheLocation: secondaryLocation
    serverRole: 'Secondary'
  }
}

output primaryLocation string = location
output existingPrimaryCacheSubnetId string = primarySubnetId
output newPrimaryCacheId string = newPrimaryCacheName_resource.id
output secondaryLocation string = secondaryLocation
output existingSecondaryCacheSubnetId string = secondarySubnetId
output newSecondaryCacheId string = newSecondaryCacheName_resource.id
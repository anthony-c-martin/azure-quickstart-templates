param location string {
  metadata: {
    description: 'The location of the existing primary virtual network and new primary cache.'
  }
  default: resourceGroup().location
}
param existingPrimaryVirtualNetworkResourceGroupName string {
  metadata: {
    description: 'The name of the resource group of the existing primary virtual network.'
  }
}
param existingPrimaryVirtualNetworkName string {
  metadata: {
    description: 'The name of the existing primary virtual network.'
  }
}
param existingPrimaryCacheSubnetName string {
  metadata: {
    description: 'The name of the existing primary cache subnet.'
  }
}
param newPrimaryCacheName string {
  metadata: {
    description: 'The name of the new primary cache.'
  }
}
param secondaryLocation string {
  metadata: {
    description: 'The location of the existing secondary virtual network and new secondary cache.'
  }
}
param existingSecondaryVirtualNetworkResourceGroupName string {
  metadata: {
    description: 'The name of the resource group of the existing secondary virtual network.'
  }
}
param existingSecondaryVirtualNetworkName string {
  metadata: {
    description: 'The name of the existing secondary virtual network.'
  }
}
param existingSecondaryCacheSubnetName string {
  metadata: {
    description: 'The name of the existing secondary cache subnet.'
  }
}
param newSecondaryCacheName string {
  metadata: {
    description: 'The name of the new secondary cache.'
  }
}

var primarySubnetId = resourceId(existingPrimaryVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingPrimaryVirtualNetworkName, existingPrimaryCacheSubnetName)
var secondarySubnetId = resourceId(existingSecondaryVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingSecondaryVirtualNetworkName, existingSecondaryCacheSubnetName)

resource newPrimaryCacheName_res 'Microsoft.Cache/Redis@2018-03-01' = {
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

resource newSecondaryCacheName_res 'Microsoft.Cache/Redis@2018-03-01' = {
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
  name: '${newPrimaryCacheName}/${newSecondaryCacheName}'
  properties: {
    linkedRedisCacheId: newSecondaryCacheName_res.id
    linkedRedisCacheLocation: secondaryLocation
    serverRole: 'Secondary'
  }
}

output primaryLocation string = location
output existingPrimaryCacheSubnetId string = primarySubnetId
output newPrimaryCacheId string = newPrimaryCacheName_res.id
output secondaryLocation_out string = secondaryLocation
output existingSecondaryCacheSubnetId string = secondarySubnetId
output newSecondaryCacheId string = newSecondaryCacheName_res.id
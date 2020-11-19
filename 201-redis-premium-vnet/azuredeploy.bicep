param location string {
  metadata: {
    description: 'The location of the existing Virtual Network and for the new Redis Cache.'
  }
  default: resourceGroup().location
}
param redisCacheName string {
  metadata: {
    description: 'The name of the Azure Redis Cache to create.'
  }
}
param redisCacheCapacity int {
  allowed: [
    1
    2
    3
    4
  ]
  metadata: {
    description: 'The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).'
  }
  default: 1
}
param existingVirtualNetworkResourceGroupName string {
  metadata: {
    description: 'The resource group of the existing Virtual Network.'
  }
  default: resourceGroup().name
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'The name of the existing Virtual Network.'
  }
}
param existingSubnetName string {
  metadata: {
    description: 'The name of the existing subnet.'
  }
}
param enableNonSslPort bool {
  metadata: {
    description: 'Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).'
  }
  default: false
}

var subnetId = resourceId(existingVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)

resource redisCacheName_resource 'Microsoft.Cache/Redis@2019-07-01' = {
  name: redisCacheName
  location: location
  properties: {
    enableNonSslPort: enableNonSslPort
    sku: {
      capacity: redisCacheCapacity
      family: 'P'
      name: 'Premium'
    }
    subnetId: subnetId
  }
}
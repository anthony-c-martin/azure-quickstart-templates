@description('The location of the existing Virtual Network and for the new Redis Cache.')
param location string = resourceGroup().location

@description('The name of the Azure Redis Cache to create.')
param redisCacheName string

@allowed([
  1
  2
  3
  4
])
@description('The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).')
param redisCacheCapacity int = 1

@description('The resource group of the existing Virtual Network.')
param existingVirtualNetworkResourceGroupName string = resourceGroup().name

@description('The name of the existing Virtual Network.')
param existingVirtualNetworkName string

@description('The name of the existing subnet.')
param existingSubnetName string

@description('Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).')
param enableNonSslPort bool = false

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
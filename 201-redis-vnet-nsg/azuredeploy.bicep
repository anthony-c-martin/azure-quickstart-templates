@description('The location of the existing Virtual Network and new Network Security Group.')
param location string = resourceGroup().location

@description('The resource group of the existing Virtual Network.')
param existingVirtualNetworkResourceGroupName string = resourceGroup().name

@description('The name of the existing Virtual Network.')
param existingVirtualNetworkName string

@description('The name of the existing subnet.')
param existingSubnetName string

@description('The name of the new Network Security Group.')
param newNsgName string

var subnetId = resourceId(existingVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)

resource newNsgName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: newNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_Outbound_Storage_PKI'
        properties: {
          description: 'Redis dependencies on Azure Storage/PKI (Internet)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_Outbound_DNS'
        properties: {
          description: 'Redis dependencies on DNS (Internet/VNet)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_Outbound_RedisPortsWithinSubnet'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '8443'
            '10221-10231'
            '20226'
            '13000-13999'
            '15000-15999'
          ]
          sourceAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_Inbound_ClientEndpoints'
        properties: {
          description: 'Client communication to Redis, Azure load balancing'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
          ]
          sourceAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Inbound_ClientCommunicationWithinVNET'
        properties: {
          description: 'Client communication to Redis, Azure load balancing'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '13000-13999'
            '15000-15999'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Inbound_LoadBalancingWithinVNET'
        properties: {
          description: 'Client communication to Redis, Azure load balancing'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '13000-13999'
            '15000-15999'
          ]
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Inbound_InternalRedisCommunication'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8443'
            '10221-10231'
            '20226'
          ]
          sourceAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 203
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Inbound_LoadBalancerToRedisInternalAddresses'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '10221-10231'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 204
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Inbound_LoadBalancing'
        properties: {
          description: 'Azure load balancing'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8500'
            '16001'
          ]
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: reference(subnetId, '2018-04-01').addressPrefix
          access: 'Allow'
          priority: 205
          direction: 'Inbound'
        }
      }
    ]
  }
}

module associateNsg './nested_associateNsg.bicep' = {
  name: 'associateNsg'
  scope: resourceGroup(existingVirtualNetworkResourceGroupName)
  params: {
    reference_variables_subnetId_2020_05_01_addressPrefix: reference(subnetId, '2020-05-01')
    resourceId_Microsoft_Network_networkSecurityGroups_parameters_newNsgName: newNsgName_resource.id
    existingVirtualNetworkName: existingVirtualNetworkName
    existingSubnetName: existingSubnetName
    location: location
  }
}

output existingVirtualNetworkName string = existingVirtualNetworkName
output existingSubnetName string = existingSubnetName
output subnetAddressPrefix string = reference(subnetId, '2018-04-01').addressPrefix
output newNsgName string = newNsgName
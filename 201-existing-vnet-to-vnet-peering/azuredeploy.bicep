@description('Set the local VNet name')
param existingLocalVirtualNetworkName string

@description('Set the remote VNet name')
param existingRemoteVirtualNetworkName string

@description('Sets the remote VNet Resource group')
param existingRemoteVirtualNetworkResourceGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource existingLocalVirtualNetworkName_peering_to_remote_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = {
  name: '${existingLocalVirtualNetworkName}/peering-to-remote-vnet'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(existingRemoteVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks', existingRemoteVirtualNetworkName)
    }
  }
}
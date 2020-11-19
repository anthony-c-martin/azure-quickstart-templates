param existingLocalVirtualNetworkName string {
  metadata: {
    description: 'Set the local VNet name'
  }
}
param existingRemoteVirtualNetworkName string {
  metadata: {
    description: 'Set the remote VNet name'
  }
}
param existingRemoteVirtualNetworkResourceGroupName string {
  metadata: {
    description: 'Sets the remote VNet Resource group'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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
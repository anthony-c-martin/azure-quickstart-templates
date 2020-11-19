param virtualNetworkName string {
  metadata: {
    description: 'Name of the VNet.'
  }
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Address space for the VNet.'
  }
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'The prefix for the GatewaySubnet where the VirtualNetworkGateway will be deployed. This must be at least /29.'
  }
}
param gatewayPublicIPName string {
  metadata: {
    description: 'The name of the PublicIP attached to the VirtualNetworkGateway.'
  }
}
param gatewayName string {
  metadata: {
    description: 'The name of the VirtualNetworkGateway.'
  }
}
param gatewaySku string {
  metadata: {
    description: 'The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.'
  }
}
param vpnClientAddressPoolPrefix string {
  metadata: {
    description: 'The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network.'
  }
}
param clientRootCertName string {
  metadata: {
    description: 'The name of the client root certificate used to authenticate VPN clients. This is a common name used to identify the root cert.'
  }
}
param clientRootCertData string {
  metadata: {
    description: 'Client root certificate data used to authenticate VPN clients.'
  }
}
param revokedCertName string {
  metadata: {
    description: 'The name of revoked certificate, if any. This is a common name used to identify a given revoked certificate.'
  }
}
param revokedCertThumbprint string {
  metadata: {
    description: 'Thumbprint of the revoked certificate. This would revoke VPN client certificates matching this thumbprint from connecting to the VNet.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'GatewaySubnet')

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource gatewayPublicIPName_res 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_res 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: gatewayPublicIPName_res.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnClientRootCertificates: [
        {
          name: clientRootCertName
          properties: {
            publicCertData: clientRootCertData
          }
        }
      ]
      vpnClientRevokedCertificates: [
        {
          name: revokedCertName
          properties: {
            thumbprint: revokedCertThumbprint
          }
        }
      ]
    }
  }
  dependsOn: [
    virtualNetworkName_res
  ]
}
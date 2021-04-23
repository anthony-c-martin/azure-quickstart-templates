@description('Name of the VNet.')
param virtualNetworkName string

@description('Address space for the VNet.')
param vnetAddressPrefix string

@description('The prefix for the GatewaySubnet where the VirtualNetworkGateway will be deployed. This must be at least /29.')
param gatewaySubnetPrefix string

@description('The name of the PublicIP attached to the VirtualNetworkGateway.')
param gatewayPublicIPName string

@description('The name of the VirtualNetworkGateway.')
param gatewayName string

@description('The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.')
param gatewaySku string

@description('The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network.')
param vpnClientAddressPoolPrefix string

@description('The name of the client root certificate used to authenticate VPN clients. This is a common name used to identify the root cert.')
param clientRootCertName string

@description('Client root certificate data used to authenticate VPN clients.')
param clientRootCertData string

@description('The name of revoked certificate, if any. This is a common name used to identify a given revoked certificate.')
param revokedCertName string

@description('Thumbprint of the revoked certificate. This would revoke VPN client certificates matching this thumbprint from connecting to the VNet.')
param revokedCertThumbprint string

@description('Location for all resources.')
param location string = resourceGroup().location

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'GatewaySubnet')

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
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
            id: gatewayPublicIPName_resource.id
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
    virtualNetworkName_resource
  ]
}
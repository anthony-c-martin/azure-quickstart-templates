param gatewayType string {
  allowed: [
    'ExpressRoute'
  ]
  metadata: {
    description: 'The type of gateway to deploy. For connecting to ExpressRoute circuits, the gateway must be of type ExpressRoute. Other types are Vpn.'
  }
  default: 'ExpressRoute'
}
param connectionType string {
  allowed: [
    'ExpressRoute'
  ]
  metadata: {
    description: 'The type of connection. For connecting to ExpressRoute circuits, the connectionType must be of type ExpressRoute. Other types are IPsec and Vnet2Vnet.'
  }
  default: 'ExpressRoute'
}
param virtualNetworkName string {
  metadata: {
    description: 'The name of the virtual network to create.'
  }
}
param addressPrefix string {
  metadata: {
    description: 'The address space in CIDR notation for the new virtual network.'
  }
}
param subnetName string {
  metadata: {
    description: 'The name of the first subnet in the new virtual network.'
  }
}
param gatewaySubnet string {
  allowed: [
    'GatewaySubnet'
  ]
  metadata: {
    description: 'The name of the subnet where Gateway is to be deployed. This must always be named GatewaySubnet.'
  }
  default: 'GatewaySubnet'
}
param subnetPrefix string {
  metadata: {
    description: 'The address range in CIDR notation for the first subnet.'
  }
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'The address range in CIDR notation for the Gateway subnet. For ExpressRoute enabled Gateways, this must be minimum of /28.'
  }
}
param gatewayPublicIPName string {
  metadata: {
    description: 'The resource name given to the public IP attached to the gateway.'
  }
}
param gatewayName string {
  metadata: {
    description: 'The resource name given to the ExpressRoute gateway.'
  }
}
param connectionName string {
  metadata: {
    description: 'The resource name given to the Connection which links VNet Gateway to ExpressRoute circuit.'
  }
}
param circuitName string {
  metadata: {
    description: 'The name of the ExpressRoute circuit with which the VNet Gateway needs to connect. The Circuit must be already created successfully and must have its circuitProvisioningState property set to \'Enabled\', and serviceProviderProvisioningState property set to \'Provisioned\'. The Circuit must also have a BGP Peering of type AzurePrivatePeering.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, gatewaySubnet)
var routingWeight = 3

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
      {
        name: gatewaySubnet
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource gatewayPublicIPName_res 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_res 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
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
    gatewayType: gatewayType
  }
}

resource connectionName_res 'Microsoft.Network/connections@2015-06-15' = {
  name: connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName_res.id
    }
    peer: {
      id: resourceId('Microsoft.Network/expressRouteCircuits', circuitName)
    }
    connectionType: connectionType
    routingWeight: routingWeight
  }
}
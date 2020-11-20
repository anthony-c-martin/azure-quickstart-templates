param existingVnetName string {
  metadata: {
    description: 'Name of the existing first VNET. This VNET must already have a subnet named GatewaySubnet defined with a minimum /29 address prefix'
  }
}
param existingVnetLocation string {
  allowed: [
    'West US'
    'East US'
    'East US 2'
    'Central US'
    'South Central US'
    'North Central US'
    'North Europe'
    'West Europe'
    'East Asia'
    'Southeast Asia'
    'Japan East'
    'Japan West'
    'Brazil South'
    'Australia East'
    'Australia Southeast'
    'Central India'
    'South India'
    'West India'
  ]
  metadata: {
    description: 'Region in which the first existing VNET is provisioned'
  }
}
param newVnetName string {
  metadata: {
    description: 'Name of the new second VNET.'
  }
  default: 'newVNET'
}
param newVnetAddressPrefix string {
  metadata: {
    description: 'Address space for the second VNET. This address space must not overlap with the first VNET'
  }
  default: '10.2.0.0/16'
}
param newVnetSubnetName string {
  metadata: {
    description: 'Name of the first subnet in the second VNET. Please note, an additional subnet called GatewaySubnet will be created where the VirtualNetworkGateway will be deployed. The name of that subnet must not be changed from GatewaySubnet.'
  }
  default: 'Subnet-1'
}
param newVnetSubnetPrefix string {
  metadata: {
    description: 'The IP address prefix for the first subnet in the second VNET.'
  }
  default: '10.2.0.0/24'
}
param newVnetGatewaySubnetPrefix string {
  metadata: {
    description: 'The prefix for the GatewaySubnet where the second VirtualNetworkGateway will be deployed. This must be at least /29.'
  }
  default: '10.2.254.0/29'
}
param sharedKey string {
  metadata: {
    description: 'The shared key used to establish connection between the two VirtualNetworkGateways.'
  }
}

var apiVersion = '2015-06-15'
var vnetID1 = resourceId('Microsoft.Network/virtualNetworks', existingVnetName)
var vnetID2 = newVnetName_res.id
var gatewayName1_var = '${existingVnetName}-gw'
var gatewayName2_var = '${newVnetName}-gw'
var gatewayPublicIPName1_var = '${existingVnetName}-gwip'
var gatewayPublicIPName2_var = '${newVnetName}-gwip'
var connectionName1_var = '${existingVnetName}-gwcon'
var connectionName2_var = '${newVnetName}-gwcon'
var gatewaySubnetRef1 = '${vnetID1}/subnets/GatewaySubnet'
var gatewaySubnetRef2 = '${vnetID2}/subnets/GatewaySubnet'

resource newVnetName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: newVnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        newVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: newVnetSubnetName
        properties: {
          addressPrefix: newVnetSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: newVnetGatewaySubnetPrefix
        }
      }
    ]
  }
}

resource gatewayPublicIPName1 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName1_var
  location: existingVnetLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayPublicIPName2 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName2_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName1 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
  name: gatewayName1_var
  location: existingVnetLocation
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef1
          }
          publicIPAddress: {
            id: gatewayPublicIPName1.id
          }
        }
        name: 'vnetGatewayConfig1'
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: 'false'
  }
}

resource gatewayName2 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
  name: gatewayName2_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef2
          }
          publicIPAddress: {
            id: gatewayPublicIPName2.id
          }
        }
        name: 'vnetGatewayConfig2'
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: 'false'
  }
  dependsOn: [
    gatewayName1
  ]
}

resource connectionName1 'Microsoft.Network/connections@2015-06-15' = {
  name: connectionName1_var
  location: existingVnetLocation
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName1.id
    }
    virtualNetworkGateway2: {
      id: gatewayName2.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
  }
}

resource connectionName2 'Microsoft.Network/connections@2015-06-15' = {
  name: connectionName2_var
  location: resourceGroup().location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName2.id
    }
    virtualNetworkGateway2: {
      id: gatewayName1.id
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
  }
  dependsOn: [
    connectionName1
  ]
}
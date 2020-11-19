param virtualNetworkName string {
  metadata: {
    description: 'Virtual Network name'
  }
  default: 'Application-Vnet'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Virtual Network address range'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet'
  }
  default: 'ApplicationGatewaySubnet'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet address range'
  }
  default: '10.0.0.0/24'
}
param applicationGatewayName string {
  metadata: {
    description: 'Application Gateway name'
  }
  default: 'applicationGatewayV2'
}
param minCapacity int {
  metadata: {
    description: 'Minimum instance count for Application Gateway'
  }
  default: 2
}
param frontendPort int {
  metadata: {
    description: 'Application Gateway Frontend port'
  }
  default: 80
}
param backendPort int {
  metadata: {
    description: 'Application gateway Backend port'
  }
  default: 80
}
param backendIPAddresses array {
  metadata: {
    description: 'Back end pool ip addresses'
  }
  default: [
    {
      IpAddress: '10.0.0.4'
    }
    {
      IpAddress: '10.0.0.5'
    }
  ]
}
param cookieBasedAffinity string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Cookie based affinity'
  }
  default: 'Disabled'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var appGwPublicIpName = '${applicationGatewayName}-pip'
var appGwSize = 'Standard_v2'

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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource appGwPublicIpName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: appGwPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: appGwSize
      tier: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          PublicIPAddress: {
            id: appGwPublicIpName_resource.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: frontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: backendIPAddresses
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: backendPort
          Protocol: 'Http'
          CookieBasedAffinity: cookieBasedAffinity
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIpConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
  dependsOn: [
    appGwPublicIpName_resource
    virtualNetworkName_resource
  ]
}
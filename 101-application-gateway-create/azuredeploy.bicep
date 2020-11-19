param virtualNetworkName string {
  metadata: {
    description: 'Virtual Network name'
  }
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Virtual Network address range'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Subnet Name'
  }
  default: 'subnet1'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/24'
}
param applicationGatewayName string {
  metadata: {
    description: 'Application Gateway name'
  }
  default: 'applicationGateway1'
}
param applicationGatewaySize string {
  allowed: [
    'Standard_Small'
    'Standard_Medium'
    'Standard_Large'
  ]
  metadata: {
    description: 'Application Gateway size'
  }
  default: 'Standard_Small'
}
param applicationGatewayInstanceCount int {
  allowed: [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
  ]
  metadata: {
    description: 'Application Gateway instance count'
  }
  default: 2
}
param frontendPort int {
  metadata: {
    description: 'Application Gateway front end port'
  }
  default: 80
}
param backendPort int {
  metadata: {
    description: 'Application Gateway back end port'
  }
  default: 80
}
param backendIPAddresses array {
  metadata: {
    description: 'Backend pool ip addresses'
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

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource applicationGatewayName_res 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: applicationGatewaySize
      tier: 'Standard'
      capacity: applicationGatewayInstanceCount
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: frontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: backendIPAddresses
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: backendPort
          protocol: 'Http'
          cookieBasedAffinity: cookieBasedAffinity
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
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
}
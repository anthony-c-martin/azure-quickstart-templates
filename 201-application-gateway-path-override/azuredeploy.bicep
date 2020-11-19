param addressPrefix string {
  metadata: {
    description: 'Address prefix for the Virtual Network'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/28'
}
param applicationGatewaySize string {
  allowed: [
    'Standard_Small'
    'Standard_Medium'
    'Standard_Large'
  ]
  metadata: {
    description: 'application gateway size'
  }
  default: 'Standard_Medium'
}
param capacity int {
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
    description: 'Number of instances'
  }
  default: 2
}
param backend1 string {
  metadata: {
    description: 'URL of Azure Web App 1'
  }
}
param backendPath string {
  metadata: {
    description: 'When forwarding a request, the match result of the path defined in UrlPathMap will be appended to the path defined in BackendHttpSettings.'
  }
}
param pathMatch1 string {
  metadata: {
    description: 'Path match string for Path Rule 1'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var applicationGatewayName = 'applicationGateway1'
var publicIPAddressName = 'publicIp1'
var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPRef = publicIPAddressName_resource.id
var applicationGatewayID = applicationGatewayName_resource.id

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-06-01' = {
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
    ]
  }
}

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: applicationGatewaySize
      tier: 'Standard'
      capacity: capacity
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
          PublicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: [
            {
              IpAddress: backend1
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          Path: backendPath
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIPConfiguration: {
            Id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          FrontendPort: {
            Id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          Protocol: 'Http'
          SslCertificate: null
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap1'
        properties: {
          defaultBackendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
          }
          defaultBackendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
          pathRules: [
            {
              name: 'pathRule1'
              properties: {
                paths: [
                  pathMatch1
                ]
                backendAddressPool: {
                  id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
                }
                backendHttpSettings: {
                  id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'PathBasedRouting'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener'
          }
          urlPathMap: {
            id: '${applicationGatewayID}/urlPathMaps/urlPathMap1'
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName_resource
  ]
}
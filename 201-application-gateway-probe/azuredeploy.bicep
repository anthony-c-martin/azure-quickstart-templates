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
    description: 'Backend 1'
  }
}
param probeEnabled bool {
  metadata: {
    description: 'Probe Enabled'
  }
  default: true
}
param healthyStatusCodes string {
  metadata: {
    description: 'Status codes for which the backend is healthy.'
  }
}
param probeProtocol string {
  allowed: [
    'http'
    'https'
  ]
  metadata: {
    description: 'Probe protocol to use.'
  }
  default: 'http'
}
param probeHost string {
  metadata: {
    description: 'Host header to send to the backend.'
  }
}
param probePath string {
  metadata: {
    description: 'Path invoked on the backend.'
  }
}
param probeIntervalInSeconds int {
  metadata: {
    description: 'Interval between probes in seconds.'
  }
}
param probeTimeoutInSeconds int {
  metadata: {
    description: 'Timeout of a probe request in seconds.'
  }
}
param probeUnhealthyThreshold int {
  metadata: {
    description: 'Maximum number of probe attempts until a backend is marked unhealthy.'
  }
}
param probePickHostNameFromBackendHttpSettings bool {
  metadata: {
    description: 'If set to true the host will be taken from the BackendHttpSettings or the backend address if BackendHttpSettings does not specify a custom host header.'
  }
}
param probeMinServersAvailable int {
  metadata: {
    description: 'Minimum number of servers that are kept in healthy state regardless of probe results.'
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
          ProbeEnabled: probeEnabled
          Probe: {
            id: '${applicationGatewayID}/probes/Probe1'
          }
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
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
        }
      }
    ]
    probes: [
      {
        Name: 'Probe1'
        properties: {
          Protocol: probeProtocol
          Path: probePath
          Host: probeHost
          Interval: probeIntervalInSeconds
          Timeout: probeTimeoutInSeconds
          UnhealthyThreshold: probeUnhealthyThreshold
          MinServers: probeMinServersAvailable
          Match: {
            StatusCodes: [
              healthyStatusCodes
            ]
          }
          PickHostNameFromBackendHttpSettings: probePickHostNameFromBackendHttpSettings
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName_resource
  ]
}
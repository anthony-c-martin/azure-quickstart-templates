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
param skuName string {
  allowed: [
    'Standard_Small'
    'Standard_Medium'
    'Standard_Large'
  ]
  metadata: {
    description: 'Sku Name'
  }
  default: 'Standard_Medium'
}
param capacity int {
  minValue: 1
  maxValue: 10
  metadata: {
    description: 'Number of instances'
  }
  default: 2
}
param backendIpAddressDefault string {
  metadata: {
    description: 'IP Address of Default Backend Server'
  }
}
param backendIpAddressForPathRule1 string {
  metadata: {
    description: 'IP Address of Backend Server for Path Rule 1 match'
  }
}
param backendIpAddressForPathRule2 string {
  metadata: {
    description: 'IP Address of Backend Server for Path Rule 2 match'
  }
}
param pathMatch1 string {
  metadata: {
    description: 'Path match string for Path Rule 1'
  }
}
param pathMatch2 string {
  metadata: {
    description: 'Path match string for Path Rule 2'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var applicationGatewayName_var = 'applicationGateway1'
var publicIPAddressName_var = 'publicIp1'
var virtualNetworkName_var = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPRef = publicIPAddressName.id
var applicationGatewayID = applicationGatewayName.id

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
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

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName_var
  location: location
  properties: {
    sku: {
      name: skuName
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
        name: 'appGatewayFrontendPublicIP'
        properties: {
          publicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPoolDefault'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddressDefault
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool1'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddressForPathRule1
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool2'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddressForPathRule2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendPublicIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort80'
          }
          protocol: 'Http'
          sslCertificate: null
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap1'
        properties: {
          defaultBackendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPoolDefault'
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
                  id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool1'
                }
                backendHttpSettings: {
                  id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
                }
              }
            }
            {
              name: 'pathRule2'
              properties: {
                paths: [
                  pathMatch2
                ]
                backendAddressPool: {
                  id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool2'
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
        name: 'rule1'
        properties: {
          ruleType: 'PathBasedRouting'
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
    virtualNetworkName
  ]
}